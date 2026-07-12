/* Metrics: Hourly Order Volume and Cancel Rate
Description: Orders grouped by hour of day to identify peak demand periods.
Cancel rate shows whether cancellations increase under high load.
Tables used: orders, user_actions */

WITH successful AS (
    SELECT
        EXTRACT(HOUR FROM creation_time) AS hour,
        COUNT(DISTINCT order_id) AS successful_orders
    FROM orders
    WHERE order_id NOT IN (
        SELECT order_id FROM user_actions WHERE action = 'cancel_order'
    )
    GROUP BY hour
),

canceled AS (
    SELECT
        EXTRACT(HOUR FROM creation_time) AS hour,
        COUNT(DISTINCT order_id) AS canceled_orders
    FROM orders
    WHERE order_id IN (
        SELECT order_id FROM user_actions WHERE action = 'cancel_order'
    )
    GROUP BY hour
),

total_orders AS (
    SELECT
        EXTRACT(HOUR FROM creation_time) AS hour,
        COUNT(DISTINCT order_id) AS orders
    FROM orders
    GROUP BY hour
)

SELECT
    hour::integer,
    successful_orders,
    canceled_orders,
    ROUND(canceled_orders / orders::decimal, 3) AS cancel_rate
FROM successful
LEFT JOIN canceled     USING (hour)
LEFT JOIN total_orders USING (hour)
ORDER BY hour;

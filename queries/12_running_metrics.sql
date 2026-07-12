/* Metrics: Running ARPU, Running ARPPU, Running AOV
Description: Cumulative versions of ARPU, ARPPU, and AOV recalculated daily.
Growing Running ARPU with stable Running AOV suggests users place more orders over time.
Tables used: orders, user_actions, products */

WITH daily_revenue AS (
    SELECT
        creation_time::date AS date,
        SUM(price) AS revenue
    FROM (
        SELECT creation_time, UNNEST(product_ids) AS product_id
        FROM orders
        WHERE order_id NOT IN (
            SELECT order_id FROM user_actions WHERE action = 'cancel_order'
        )
    ) t1
    LEFT JOIN products USING (product_id)
    GROUP BY date
),

new_users AS (
    SELECT
        first_date AS date,
        COUNT(*) AS new_users
    FROM (
        SELECT user_id, MIN(time::date) AS first_date
        FROM user_actions
        GROUP BY user_id
    ) t
    GROUP BY first_date
),

pay_users AS (
    SELECT
        first_date AS date,
        COUNT(DISTINCT user_id) AS paying_users
    FROM (
        SELECT user_id, MIN(time::date) AS first_date
        FROM user_actions
        WHERE order_id NOT IN (
            SELECT order_id FROM user_actions WHERE action = 'cancel_order'
        )
        GROUP BY user_id
    ) t
    GROUP BY first_date
),

total_orders AS (
    SELECT
        creation_time::date AS date,
        COUNT(order_id) AS orders
    FROM orders
    WHERE order_id NOT IN (
        SELECT order_id FROM user_actions WHERE action = 'cancel_order'
    )
    GROUP BY date
)

SELECT
    date,
    ROUND(SUM(revenue) OVER (ORDER BY date)::decimal / SUM(new_users)    OVER (ORDER BY date), 2) AS running_arpu,
    ROUND(SUM(revenue) OVER (ORDER BY date)::decimal / SUM(paying_users) OVER (ORDER BY date), 2) AS running_arppu,
    ROUND(SUM(revenue) OVER (ORDER BY date)::decimal / SUM(orders)       OVER (ORDER BY date), 2) AS running_aov
FROM daily_revenue
LEFT JOIN new_users    USING (date)
LEFT JOIN pay_users    USING (date)
LEFT JOIN total_orders USING (date)
ORDER BY date;

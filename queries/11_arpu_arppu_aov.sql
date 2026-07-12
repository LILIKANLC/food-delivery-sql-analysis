/* Metrics: ARPU, ARPPU, AOV by Day
Description:
ARPU  — average revenue per user (all users)
ARPPU — average revenue per paying user
AOV   — average order value
Tables used: orders, user_actions, products */

WITH revenue AS (
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

unique_users AS (
    SELECT
        time::date AS date,
        COUNT(DISTINCT user_id) AS unique_users
    FROM user_actions
    GROUP BY date
),

pay_users AS (
    SELECT
        time::date AS date,
        COUNT(DISTINCT user_id) AS paying_users
    FROM user_actions
    WHERE order_id NOT IN (
        SELECT order_id FROM user_actions WHERE action = 'cancel_order'
    )
    GROUP BY date
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
    revenue.date,
    ROUND(revenue::decimal / unique_users, 2) AS arpu,
    ROUND(revenue::decimal / paying_users, 2) AS arppu,
    ROUND(revenue::decimal / orders,       2) AS aov
FROM revenue
LEFT JOIN unique_users USING (date)
LEFT JOIN pay_users    USING (date)
LEFT JOIN total_orders USING (date)
ORDER BY date;

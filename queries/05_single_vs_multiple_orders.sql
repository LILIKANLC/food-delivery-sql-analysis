/* Metrics: Single vs Multiple Orders per Day
Description: Share of paying users who placed exactly one order vs more than one. 
Helps understand daily user behavior and engagement depth.
Tables used: user_actions */

WITH pays AS (
    SELECT
        time::date AS date,
        COUNT(DISTINCT user_id) AS paying_users
    FROM user_actions
    WHERE order_id NOT IN (
        SELECT order_id FROM user_actions WHERE action = 'cancel_order'
    )
    GROUP BY date
),

orders_per_user AS (
    SELECT
        time::date AS date,
        user_id,
        COUNT(DISTINCT order_id) AS orders_cnt
    FROM user_actions
    WHERE order_id NOT IN (
        SELECT order_id FROM user_actions WHERE action = 'cancel_order'
    )
    GROUP BY time::date, user_id
),

singles AS (
    SELECT
        date,
        COUNT(DISTINCT user_id) AS single_order_users
    FROM orders_per_user
    WHERE orders_cnt = 1
    GROUP BY date
),

several AS (
    SELECT
        date,
        COUNT(DISTINCT user_id) AS several_orders_users
    FROM orders_per_user
    WHERE orders_cnt > 1
    GROUP BY date
)

SELECT
    p.date,
    ROUND(single_order_users   * 100.0 / paying_users, 2) AS single_order_users_share,
    ROUND(several_orders_users * 100.0 / paying_users, 2) AS several_orders_users_share
FROM pays AS p
LEFT JOIN singles AS si USING (date)
LEFT JOIN several AS s  USING (date)
ORDER BY p.date;

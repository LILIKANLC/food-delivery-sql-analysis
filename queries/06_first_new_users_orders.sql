/* Metrics: Total Orders, First Orders, New User Orders and Their Shares
Description: Tracks how many orders come from first-time buyers vs returning users.
As the service matures, the share of first orders is expected to gradually decline.
Tables used: user_actions */

WITH total_orders AS (
    SELECT
        time::date AS date,
        COUNT(DISTINCT order_id) AS orders
    FROM user_actions
    WHERE order_id NOT IN (
        SELECT order_id FROM user_actions WHERE action = 'cancel_order'
    )
    GROUP BY date
),

first_orders AS (
    SELECT
        first_date AS date,
        COUNT(*) AS first_orders
    FROM (
        SELECT
            user_id,
            MIN(time::date) AS first_date
        FROM user_actions
        WHERE order_id NOT IN (
            SELECT order_id FROM user_actions WHERE action = 'cancel_order'
        )
        GROUP BY user_id
    ) t
    GROUP BY first_date
),

first_users AS (
    SELECT
        user_id,
        MIN(time::date) AS first_date
    FROM user_actions
    GROUP BY user_id
),

orders_per_day AS (
    SELECT
        user_id,
        time::date AS date,
        COUNT(DISTINCT order_id) AS orders_cnt
    FROM user_actions
    WHERE order_id NOT IN (
        SELECT order_id FROM user_actions WHERE action = 'cancel_order'
    )
    GROUP BY user_id, time::date
),

new_users_orders AS (
    SELECT
        fu.first_date AS date,
        SUM(COALESCE(opd.orders_cnt, 0))::int AS new_users_orders
    FROM first_users fu
    LEFT JOIN orders_per_day opd
        ON fu.user_id = opd.user_id
       AND fu.first_date = opd.date
    GROUP BY fu.first_date
)

SELECT
    t.date,
    t.orders,
    f.first_orders,
    n.new_users_orders,
    ROUND(f.first_orders     * 100.0 / t.orders, 2) AS first_orders_share,
    ROUND(n.new_users_orders * 100.0 / t.orders, 2) AS new_users_orders_share
FROM total_orders t
LEFT JOIN first_orders     f USING (date)
LEFT JOIN new_users_orders n USING (date)
ORDER BY t.date;

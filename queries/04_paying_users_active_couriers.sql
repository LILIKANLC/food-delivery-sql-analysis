/* Metrics: Paying Users, Active Couriers, and Their Shares
Description: Paying users are those with at least one non-cancelled order.
Active couriers are those who both accepted and delivered at least one order.
Tables used: user_actions, courier_actions */


WITH user_stats AS (
    SELECT
        date,
        new_users,
        SUM(new_users) OVER (ORDER BY date)::int AS total_users
    FROM (
        SELECT
            first_date AS date,
            COUNT(*) AS new_users
        FROM (
            SELECT
                user_id,
                MIN(time::date) AS first_date
            FROM user_actions
            GROUP BY user_id
        ) t
        GROUP BY first_date
    ) t2
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

users_all AS (
    SELECT
        us.date,
        paying_users,
        ROUND(paying_users * 100.0 / total_users, 2) AS paying_users_share
    FROM user_stats AS us
    JOIN pay_users AS pu USING (date)
),

courier_stats AS (
    SELECT
        date,
        new_couriers,
        SUM(new_couriers) OVER (ORDER BY date)::int AS total_couriers
    FROM (
        SELECT
            first_date AS date,
            COUNT(*) AS new_couriers
        FROM (
            SELECT
                courier_id,
                MIN(time::date) AS first_date
            FROM courier_actions
            GROUP BY courier_id
        ) t
        GROUP BY first_date
    ) t2
),

act_couriers AS (
    SELECT
        time::date AS date,
        COUNT(DISTINCT courier_id) AS active_couriers
    FROM courier_actions
    WHERE order_id IN (SELECT order_id FROM courier_actions WHERE action = 'accept_order')
      AND order_id IN (SELECT order_id FROM courier_actions WHERE action = 'deliver_order')
    GROUP BY date
),

couriers_all AS (
    SELECT
        cs.date,
        active_couriers,
        ROUND(active_couriers * 100.0 / total_couriers, 2) AS active_couriers_share
    FROM courier_stats AS cs
    JOIN act_couriers AS ac USING (date)
)

SELECT
    ca.date,
    paying_users,
    active_couriers,
    paying_users_share,
    active_couriers_share
FROM users_all AS ua
JOIN couriers_all AS ca USING (date)
ORDER BY ca.date;

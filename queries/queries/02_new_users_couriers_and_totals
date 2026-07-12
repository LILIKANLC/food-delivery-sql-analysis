/* Metrics: New Users, New Couriers, Total Users, Total Couriers
Description: Tracks daily audience growth by counting first appearances of each user and courier. 
Cumulative totals show overall platform scale over time.
Tables used: user_actions, courier_actions */


WITH user_stats AS (
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
),

courier_stats AS (
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
),

combined AS (
    SELECT
        COALESCE(u.date, c.date)       AS date,
        COALESCE(new_users, 0)::int    AS new_users,
        COALESCE(new_couriers, 0)::int AS new_couriers
    FROM user_stats u
    FULL JOIN courier_stats c USING (date)
)

SELECT
    date,
    new_users,
    new_couriers,
    SUM(new_users)    OVER (ORDER BY date)::int AS total_users,
    SUM(new_couriers) OVER (ORDER BY date)::int AS total_couriers
FROM combined
ORDER BY date;

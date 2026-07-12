/* Metrics: Growth Rate of New and Total Users and Couriers
Description: Day-over-day percentage change in new and total users and couriers.
Helps identify acceleration or slowdown in audience growth.
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
),

with_totals AS (
    SELECT
        date,
        new_users,
        new_couriers,
        SUM(new_users)    OVER (ORDER BY date)::int AS total_users,
        SUM(new_couriers) OVER (ORDER BY date)::int AS total_couriers
    FROM combined
),

with_prev AS (
    SELECT
        date,
        new_users,
        new_couriers,
        total_users,
        total_couriers,
        LAG(new_users)      OVER (ORDER BY date) AS prev_new_users,
        LAG(new_couriers)   OVER (ORDER BY date) AS prev_new_couriers,
        LAG(total_users)    OVER (ORDER BY date) AS prev_total_users,
        LAG(total_couriers) OVER (ORDER BY date) AS prev_total_couriers
    FROM with_totals
)

SELECT
    date,
    new_users,
    new_couriers,
    total_users,
    total_couriers,
    ROUND((new_users    - prev_new_users)    * 100.0 / prev_new_users,    2) AS new_users_change,
    ROUND((new_couriers - prev_new_couriers) * 100.0 / prev_new_couriers, 2) AS new_couriers_change,
    ROUND((total_users    - prev_total_users)    * 100.0 / prev_total_users,    2) AS total_users_growth,
    ROUND((total_couriers - prev_total_couriers) * 100.0 / prev_total_couriers, 2) AS total_couriers_growth
FROM with_prev
ORDER BY date;

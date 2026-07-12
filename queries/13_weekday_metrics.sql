/* Metrics: ARPU, ARPPU, AOV by Day of Week
Description: Monetization metrics grouped by weekday to identify weekly patterns. ISODOW: 1 = Monday, 7 = Sunday.
Date range: two full weeks (2022-08-26 to 2022-09-08)
Tables used: orders, user_actions, products */

WITH revenue AS (
    SELECT
        TO_CHAR(creation_time::date, 'Day') AS weekday,
        EXTRACT(ISODOW FROM creation_time)  AS weekday_number,
        SUM(price) AS revenue
    FROM (
        SELECT creation_time, UNNEST(product_ids) AS product_id
        FROM orders
        WHERE order_id NOT IN (
            SELECT order_id FROM user_actions WHERE action = 'cancel_order'
        )
        AND creation_time::date BETWEEN '2022-08-26' AND '2022-09-08'
    ) t1
    LEFT JOIN products USING (product_id)
    GROUP BY weekday, weekday_number
),

unique_users AS (
    SELECT
        TO_CHAR(time::date, 'Day')  AS weekday,
        EXTRACT(ISODOW FROM time)   AS weekday_number,
        COUNT(DISTINCT user_id)     AS unique_users
    FROM user_actions
    WHERE time::date BETWEEN '2022-08-26' AND '2022-09-08'
    GROUP BY weekday, weekday_number
),

pay_users AS (
    SELECT
        TO_CHAR(time::date, 'Day')  AS weekday,
        EXTRACT(ISODOW FROM time)   AS weekday_number,
        COUNT(DISTINCT user_id)     AS paying_users
    FROM user_actions
    WHERE order_id NOT IN (
        SELECT order_id FROM user_actions WHERE action = 'cancel_order'
    )
    AND time::date BETWEEN '2022-08-26' AND '2022-09-08'
    GROUP BY weekday, weekday_number
),

total_orders AS (
    SELECT
        TO_CHAR(creation_time::date, 'Day') AS weekday,
        EXTRACT(ISODOW FROM creation_time)  AS weekday_number,
        COUNT(order_id)                     AS orders
    FROM orders
    WHERE order_id NOT IN (
        SELECT order_id FROM user_actions WHERE action = 'cancel_order'
    )
    AND creation_time::date BETWEEN '2022-08-26' AND '2022-09-08'
    GROUP BY weekday, weekday_number
)

SELECT
    weekday,
    weekday_number,
    ROUND(revenue::decimal / unique_users, 2) AS arpu,
    ROUND(revenue::decimal / paying_users, 2) AS arppu,
    ROUND(revenue::decimal / orders,       2) AS aov
FROM revenue
LEFT JOIN unique_users USING (weekday, weekday_number)
LEFT JOIN pay_users    USING (weekday, weekday_number)
LEFT JOIN total_orders USING (weekday, weekday_number)
ORDER BY weekday_number;

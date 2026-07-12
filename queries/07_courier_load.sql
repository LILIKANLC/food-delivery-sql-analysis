/* Metrics: Users per Courier, Orders per Courier
Description: Measures daily workload per active courier. 
Helps assess whether courier supply matches demand.
Tables used: user_actions, courier_actions */

WITH pay_users AS (
    SELECT
        time::date AS date,
        COUNT(DISTINCT user_id) AS paying_users
    FROM user_actions
    WHERE order_id NOT IN (
        SELECT order_id FROM user_actions WHERE action = 'cancel_order'
    )
    GROUP BY date
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

total_orders AS (
    SELECT
        time::date AS date,
        COUNT(DISTINCT order_id) AS orders
    FROM user_actions
    WHERE order_id NOT IN (
        SELECT order_id FROM user_actions WHERE action = 'cancel_order'
    )
    GROUP BY date
)

SELECT
    pu.date,
    ROUND(paying_users::decimal / active_couriers, 2) AS users_per_courier,
    ROUND(orders::decimal       / active_couriers, 2) AS orders_per_courier
FROM pay_users AS pu
LEFT JOIN act_couriers AS ac USING (date)
LEFT JOIN total_orders AS t  USING (date)
ORDER BY pu.date;

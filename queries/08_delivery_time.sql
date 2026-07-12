/* Metric: Average Delivery Time (minutes)
Description: Average time between order acceptance and delivery per day.
Cancelled orders are excluded.
Tables used: courier_actions, user_actions */

WITH delivery_times AS (
    SELECT
        order_id,
        MIN(time) AS accept_time,
        MAX(time) AS deliver_time
    FROM courier_actions
    WHERE order_id NOT IN (
        SELECT order_id FROM user_actions WHERE action = 'cancel_order'
    )
    GROUP BY order_id
)

SELECT
    deliver_time::date AS date,
    ROUND(AVG(EXTRACT(EPOCH FROM (deliver_time - accept_time)) / 60))::integer AS minutes_to_deliver
FROM delivery_times
GROUP BY date
ORDER BY date;

/* Metrics: New User Revenue vs Returning User Revenue
Description: Splits daily revenue between users placing their first order ever and existing users.
Tables used: orders, user_actions, products */

WITH info_orders AS (
    SELECT
        o.order_id,
        ua.user_id,
        o.creation_time::date AS date
    FROM orders o
    JOIN user_actions ua USING (order_id)
    WHERE ua.action = 'create_order'
      AND o.order_id NOT IN (
          SELECT order_id FROM user_actions WHERE action = 'cancel_order'
      )
),

info_products AS (
    SELECT
        order_id,
        SUM(price) AS order_price
    FROM (
        SELECT order_id, UNNEST(product_ids) AS product_id
        FROM orders
        WHERE order_id NOT IN (
            SELECT order_id FROM user_actions WHERE action = 'cancel_order'
        )
    ) t
    LEFT JOIN products USING (product_id)
    GROUP BY order_id
),

info_orders_products AS (
    SELECT order_id, user_id, date, order_price
    FROM info_orders
    JOIN info_products USING (order_id)
),

new_users AS (
    SELECT
        user_id,
        MIN(time::date) AS first_date
    FROM user_actions
    GROUP BY user_id
),

info_revenue AS (
    SELECT
        date,
        SUM(order_price) AS revenue
    FROM info_orders_products
    GROUP BY date
),

new_users_revenue AS (
    SELECT
        date,
        SUM(order_price) AS new_users_revenue
    FROM info_orders_products
    LEFT JOIN new_users USING (user_id)
    WHERE date = first_date
    GROUP BY date
)

SELECT
    date,
    revenue,
    new_users_revenue,
    ROUND(new_users_revenue * 100.0 / revenue,             2) AS new_users_revenue_share,
    ROUND((revenue - new_users_revenue) * 100.0 / revenue, 2) AS old_users_revenue_share
FROM info_revenue
LEFT JOIN new_users_revenue USING (date)
ORDER BY date;

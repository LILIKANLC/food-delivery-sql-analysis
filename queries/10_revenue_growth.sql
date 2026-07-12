/* Metrics: Daily Revenue, Cumulative Revenue, Revenue Growth Rate
Description: Revenue calculated by unnesting product_ids array and joining with products.
Growth rate shows day-over-day change.
Tables used: orders, user_actions, products */

WITH order_products AS (
    SELECT
        creation_time,
        UNNEST(product_ids) AS product_id
    FROM orders
    WHERE order_id NOT IN (
        SELECT order_id FROM user_actions WHERE action = 'cancel_order'
    )
),

daily_revenue AS (
    SELECT
        creation_time::date AS date,
        SUM(price) AS revenue
    FROM order_products
    LEFT JOIN products USING (product_id)
    GROUP BY date
)

SELECT
    date,
    revenue,
    SUM(revenue) OVER (ORDER BY date) AS total_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY date))
              / LAG(revenue) OVER (ORDER BY date),
        2
    ) AS revenue_change
FROM daily_revenue
ORDER BY date;

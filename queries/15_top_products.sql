/* Metric: Revenue Share by Product
Description:
Calculates total revenue and revenue share for each product.
Products contributing less than 0.5% of total revenue are grouped into 'Other'.
Canceled orders are excluded.
Product names are translated into English.
Tables used: orders, user_actions, products */

WITH order_products AS (
    SELECT
        UNNEST(product_ids) AS product_id
    FROM orders
    WHERE order_id NOT IN (
        SELECT order_id
        FROM user_actions
        WHERE action = 'cancel_order'
    )
),

product_revenue AS (
    SELECT
        CASE name
    WHEN 'свинина' THEN 'Pork'
    WHEN 'курица' THEN 'Chicken'
    WHEN 'масло оливковое' THEN 'Olive Oil'
    WHEN 'говядина' THEN 'Beef'
    WHEN 'баранина' THEN 'Lamb'
    WHEN 'кофе зерновой' THEN 'Coffee Beans'
    WHEN 'сахар' THEN 'Sugar'
    WHEN 'кофе растворимый' THEN 'Instant Coffee'
    WHEN 'сосиски' THEN 'Sausages'
    WHEN 'энергетический напиток' THEN 'Energy Drink'
    WHEN 'сок яблочный' THEN 'Apple Juice'
    WHEN 'морс брусничный' THEN 'Lingonberry Fruit Drink'
    WHEN 'икра' THEN 'Caviar'
    WHEN 'бананы' THEN 'Bananas'
    WHEN 'макароны' THEN 'Pasta'
    WHEN 'кофе молотый' THEN 'Ground Coffee'
    WHEN 'виноград' THEN 'Grapes'
    WHEN 'кофе без кофеина' THEN 'Decaffeinated Coffee'
    WHEN 'ананас' THEN 'Pineapple'
    WHEN 'телятина' THEN 'Veal'
    WHEN 'лимонад' THEN 'Lemonade'
    WHEN 'сок апельсиновый' THEN 'Orange Juice'
    WHEN 'морс клюквенный' THEN 'Cranberry Fruit Drink'
    WHEN 'морс черничный' THEN 'Blueberry Fruit Drink'
    WHEN 'вода негазированная' THEN 'Still Water'
    WHEN 'мандарины' THEN 'Mandarins'
    WHEN 'масло подсолнечное' THEN 'Sunflower Oil'
    WHEN 'яблоки' THEN 'Apples'
    WHEN 'молоко' THEN 'Milk'
    WHEN 'чай черный в пакетиках' THEN 'Black Tea (Tea Bags)'
    WHEN 'чипсы' THEN 'Potato Chips'
    WHEN 'сок ананасовый' THEN 'Pineapple Juice'
    WHEN 'апельсины' THEN 'Oranges'
    WHEN 'сливки' THEN 'Cream'
    WHEN 'батон' THEN 'White Bread'
    WHEN 'чай черный листовой' THEN 'Loose Leaf Black Tea'
    WHEN 'шоколад черный' THEN 'Dark Chocolate'
    WHEN 'сметана' THEN 'Sour Cream'
    WHEN 'варенье' THEN 'Jam'
    WHEN 'мед' THEN 'Honey'
    WHEN 'гречка' THEN 'Buckwheat'
    WHEN 'мука' THEN 'Flour'
    WHEN 'вафли' THEN 'Wafers'
    WHEN 'овсянка' THEN 'Oatmeal'
    WHEN 'рыба копченая' THEN 'Smoked Fish'
    WHEN 'квас' THEN 'Kvass'
    WHEN 'чай травяной листовой' THEN 'Loose Leaf Herbal Tea'
    WHEN 'арбуз' THEN 'Watermelon'
    WHEN 'рыба соленая' THEN 'Salted Fish'
    WHEN 'печенье' THEN 'Cookies'
    WHEN 'хлеб' THEN 'Bread'
    WHEN 'шоколад белый' THEN 'White Chocolate'
    WHEN 'майонез' THEN 'Mayonnaise'
    WHEN 'сок мультифрукт' THEN 'Multifruit Juice'
    WHEN 'чай зеленый в пакетиках' THEN 'Green Tea (Tea Bags)'
    WHEN 'груши' THEN 'Pears'
    WHEN 'вода газированная' THEN 'Sparkling Water'
    WHEN 'чай зеленый листовой' THEN 'Loose Leaf Green Tea'
    WHEN 'сгущенка' THEN 'Condensed Milk'
    WHEN 'шпроты' THEN 'Sprats'
    WHEN 'кетчуп' THEN 'Ketchup'
    WHEN 'кексы' THEN 'Cupcakes'
    WHEN 'рис' THEN 'Rice'
    WHEN 'чай травяной в пакетиках' THEN 'Herbal Tea (Tea Bags)'
    WHEN 'чайный гриб' THEN 'Kombucha'
    WHEN 'масло кунжутное' THEN 'Sesame Oil'
    WHEN 'жевательная резинка' THEN 'Chewing Gum'
    ELSE name
END AS product_name,
        SUM(p.price) AS revenue
    FROM order_products op
    JOIN products p USING (product_id)
    GROUP BY product_name
),

with_share AS (
    SELECT
        product_name,
        revenue,
        ROUND(revenue * 100.0 / SUM(revenue) OVER (), 2) AS share_in_revenue
    FROM product_revenue
)

SELECT
    CASE
        WHEN share_in_revenue < 0.5 THEN 'Other'
        ELSE product_name
    END AS product_name,
    SUM(revenue) AS revenue,
    SUM(share_in_revenue) AS share_in_revenue
FROM with_share
GROUP BY
    CASE
        WHEN share_in_revenue < 0.5 THEN 'Other'
        ELSE product_name
    END
ORDER BY revenue DESC;

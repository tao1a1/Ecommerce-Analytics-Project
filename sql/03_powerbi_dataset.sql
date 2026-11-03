-- 03_powerbi_dataset.sql
-- 阶段 3 Power BI 数据集

USE olist_ecommerce;

-- 1. 订单级数据集

CREATE OR REPLACE VIEW mart_powerbi_orders AS
SELECT
    order_id,
    customer_unique_id,
    customer_city,
    customer_state,

    order_status,
    purchase_date,
    purchase_month,
    purchase_hour,
    purchase_day_of_week,

    item_lines,
    distinct_products,
    merchandise_value,
    freight_value,
    total_order_value,

    delivery_days,
    delivery_status,
    review_score

FROM vw_order_fact;

-- 2. 商品明细级数据集

CREATE OR REPLACE VIEW mart_powerbi_order_items AS
SELECT
    order_id,
    order_item_id,
    purchase_date,
    order_status,

    customer_unique_id,
    customer_city,
    customer_state,

    product_id,
    product_category,

    price,
    freight_value,
    item_total_value

FROM vw_order_item_fact;

-- 3. 客户级数据集

CREATE OR REPLACE VIEW mart_powerbi_customers AS
SELECT
    customer_unique_id,

    MIN(purchase_date) AS first_purchase_date,
    MAX(purchase_date) AS last_purchase_date,

    DATEDIFF(
        (
            SELECT MAX(purchase_date)
            FROM vw_order_fact
            WHERE order_status = 'delivered'
        ),
        MAX(purchase_date)
    ) AS recency_days,

    COUNT(DISTINCT order_id) AS frequency,
    ROUND(SUM(merchandise_value), 2) AS monetary,

    CASE
        WHEN COUNT(DISTINCT order_id) >= 2 THEN 1
        ELSE 0
    END AS repeat_flag

FROM vw_order_fact
WHERE order_status = 'delivered'
  AND customer_unique_id IS NOT NULL
GROUP BY customer_unique_id;

-- 4. Power BI 导入前检查

SELECT
    COUNT(*) AS order_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_orders
FROM mart_powerbi_orders;

SELECT
    COUNT(*) AS item_rows,
    COUNT(DISTINCT order_id) AS orders
FROM mart_powerbi_order_items;

SELECT
    COUNT(*) AS customer_rows,
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM mart_powerbi_customers;

-- 5. GMV 对账

SELECT
    (
        SELECT ROUND(SUM(merchandise_value), 2)
        FROM mart_powerbi_orders
        WHERE order_status = 'delivered'
    ) AS order_gmv,

    (
        SELECT ROUND(SUM(price), 2)
        FROM mart_powerbi_order_items
        WHERE order_status = 'delivered'
    ) AS item_gmv;

-- 6. 最终 KPI 检查

SELECT
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT customer_unique_id) AS customers,
    ROUND(SUM(merchandise_value), 2) AS gmv,
    ROUND(AVG(merchandise_value), 2) AS aov,
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days,
    ROUND(AVG(review_score), 2) AS avg_review_score
FROM mart_powerbi_orders
WHERE order_status = 'delivered';

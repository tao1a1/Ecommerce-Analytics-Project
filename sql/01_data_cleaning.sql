
-- 01_data_cleaning.sql
-- Olist 电商数据分析：
-- 阶段 1 数据清洗与基础建模

USE olist_ecommerce;

-- 1. 基础的数据检查

SELECT 'raw_orders' AS table_name, COUNT(*) AS row_count FROM raw_orders
UNION ALL
SELECT 'raw_customers', COUNT(*) FROM raw_customers
UNION ALL
SELECT 'raw_order_items', COUNT(*) FROM raw_order_items
UNION ALL
SELECT 'raw_products', COUNT(*) FROM raw_products
UNION ALL
SELECT 'raw_order_reviews', COUNT(*) FROM raw_order_reviews;


SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_orders
FROM raw_orders;


-- 2. 清洗订单表

CREATE OR REPLACE VIEW vw_clean_orders AS
SELECT
    NULLIF(TRIM(order_id), '') AS order_id,
    NULLIF(TRIM(customer_id), '') AS customer_id,
    LOWER(NULLIF(TRIM(order_status), '')) AS order_status,

    STR_TO_DATE(
        NULLIF(TRIM(order_purchase_timestamp), ''),
        '%Y-%m-%d %H:%i:%s'
    ) AS order_purchase_ts,

    STR_TO_DATE(
        NULLIF(TRIM(order_delivered_customer_date), ''),
        '%Y-%m-%d %H:%i:%s'
    ) AS order_delivered_customer_ts,

    STR_TO_DATE(
        NULLIF(TRIM(order_estimated_delivery_date), ''),
        '%Y-%m-%d %H:%i:%s'
    ) AS order_estimated_delivery_ts

FROM raw_orders
WHERE NULLIF(TRIM(order_id), '') IS NOT NULL;


-- 3. 清洗客户表

CREATE OR REPLACE VIEW vw_clean_customers AS
SELECT
    NULLIF(TRIM(customer_id), '') AS customer_id,
    NULLIF(TRIM(customer_unique_id), '') AS customer_unique_id,
    NULLIF(TRIM(customer_city), '') AS customer_city,
    UPPER(NULLIF(TRIM(customer_state), '')) AS customer_state
FROM raw_customers
WHERE NULLIF(TRIM(customer_id), '') IS NOT NULL;


-- 4. 清洗订单商品明细表

CREATE OR REPLACE VIEW vw_clean_order_items AS
SELECT
    NULLIF(TRIM(order_id), '') AS order_id,
    CAST(NULLIF(TRIM(order_item_id), '') AS UNSIGNED) AS order_item_id,
    NULLIF(TRIM(product_id), '') AS product_id,

    CAST(NULLIF(TRIM(price), '') AS DECIMAL(12,2)) AS price,
    CAST(NULLIF(TRIM(freight_value), '') AS DECIMAL(12,2)) AS freight_value

FROM raw_order_items
WHERE NULLIF(TRIM(order_id), '') IS NOT NULL;

-- 5. 清洗商品表 + 商品品类英文翻译

CREATE OR REPLACE VIEW vw_clean_products AS
SELECT
    NULLIF(TRIM(product_id), '') AS product_id,
    NULLIF(TRIM(product_category_name), '') AS product_category_name
FROM raw_products
WHERE NULLIF(TRIM(product_id), '') IS NOT NULL;

CREATE OR REPLACE VIEW vw_category_translation AS
SELECT
    NULLIF(TRIM(product_category_name), '') AS product_category_name,
    NULLIF(TRIM(product_category_name_english), '') AS product_category_name_english
FROM raw_category_name_translation;

CREATE OR REPLACE VIEW vw_product_dim AS
SELECT
    p.product_id,
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS product_category
FROM vw_clean_products p
LEFT JOIN vw_category_translation t
    ON p.product_category_name = t.product_category_name;

-- 6. 清洗评价表

CREATE OR REPLACE VIEW vw_clean_reviews AS
SELECT
    NULLIF(TRIM(order_id), '') AS order_id,
    CAST(NULLIF(TRIM(review_score), '') AS UNSIGNED) AS review_score
FROM raw_order_reviews
WHERE NULLIF(TRIM(order_id), '') IS NOT NULL;

-- 7. 数据质量检查

-- 7.1 检查商品价格和运费是否异常

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS missing_price,
    SUM(CASE WHEN price <= 0 THEN 1 ELSE 0 END) AS invalid_price,
    SUM(CASE WHEN freight_value < 0 THEN 1 ELSE 0 END) AS invalid_freight
FROM vw_clean_order_items;

-- 7.2 检查评价分数是否在正常范围 1-5

SELECT
    COUNT(*) AS total_reviews,
    SUM(
        CASE
            WHEN review_score NOT BETWEEN 1 AND 5
            THEN 1
            ELSE 0
        END
    ) AS invalid_review_score
FROM vw_clean_reviews;

-- 7.3 检查是否存在“送达时间早于下单时间”的异常记录

SELECT
    COUNT(*) AS invalid_delivery_date
FROM vw_clean_orders
WHERE order_delivered_customer_ts < order_purchase_ts;

-- 8. 先把一对多表汇总到“一行一订单”

CREATE OR REPLACE VIEW vw_order_items_agg AS
SELECT
    order_id,
    COUNT(*) AS item_lines,
    COUNT(DISTINCT product_id) AS distinct_products,
    ROUND(SUM(price), 2) AS merchandise_value,
    ROUND(SUM(freight_value), 2) AS freight_value,
    ROUND(SUM(price + freight_value), 2) AS total_order_value
FROM vw_clean_order_items
GROUP BY order_id;

CREATE OR REPLACE VIEW vw_reviews_agg AS
SELECT
    order_id,
    ROUND(AVG(review_score), 2) AS review_score
FROM vw_clean_reviews
GROUP BY order_id;

-- 9. 建立订单事实表：一行一订单

CREATE OR REPLACE VIEW vw_order_fact AS
SELECT
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,

    o.order_status,
    DATE(o.order_purchase_ts) AS purchase_date,
    DATE_FORMAT(o.order_purchase_ts, '%Y-%m') AS purchase_month,
    HOUR(o.order_purchase_ts) AS purchase_hour,
    DAYOFWEEK(o.order_purchase_ts) AS purchase_day_of_week,
    o.order_purchase_ts,

    COALESCE(i.item_lines, 0) AS item_lines,
    COALESCE(i.distinct_products, 0) AS distinct_products,
    COALESCE(i.merchandise_value, 0) AS merchandise_value,
    COALESCE(i.freight_value, 0) AS freight_value,
    COALESCE(i.total_order_value, 0) AS total_order_value,

    r.review_score,

    CASE
        WHEN o.order_purchase_ts IS NULL
          OR o.order_delivered_customer_ts IS NULL
        THEN NULL
        ELSE DATEDIFF(
            o.order_delivered_customer_ts,
            o.order_purchase_ts
        )
    END AS delivery_days,

    CASE
        WHEN o.order_status <> 'delivered' THEN 'Not Delivered'
        WHEN o.order_delivered_customer_ts IS NULL
          OR o.order_estimated_delivery_ts IS NULL THEN 'Unknown'
        WHEN o.order_delivered_customer_ts > o.order_estimated_delivery_ts THEN 'Late'
        ELSE 'On Time / Early'
    END AS delivery_status

FROM vw_clean_orders o
LEFT JOIN vw_clean_customers c
    ON o.customer_id = c.customer_id
LEFT JOIN vw_order_items_agg i
    ON o.order_id = i.order_id
LEFT JOIN vw_reviews_agg r
    ON o.order_id = r.order_id;

-- 10. 建立商品明细事实表：一行一个订单商品

CREATE OR REPLACE VIEW vw_order_item_fact AS
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,

    o.order_status,
    DATE(o.order_purchase_ts) AS purchase_date,

    c.customer_unique_id,
    c.customer_city,
    c.customer_state,

    COALESCE(p.product_category, 'Unknown') AS product_category,

    oi.price,
    oi.freight_value,
    oi.price + oi.freight_value AS item_total_value

FROM vw_clean_order_items oi
JOIN vw_clean_orders o
    ON oi.order_id = o.order_id
LEFT JOIN vw_clean_customers c
    ON o.customer_id = c.customer_id
LEFT JOIN vw_product_dim p
    ON oi.product_id = p.product_id;

-- 11. 最后检查

SELECT
    COUNT(*) AS fact_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicated_orders
FROM vw_order_fact;


SELECT
    ROUND(SUM(merchandise_value), 2) AS delivered_gmv
FROM vw_order_fact
WHERE order_status = 'delivered';


-- 02_business_analysis.sql
-- 阶段 2 业务分析

USE olist_ecommerce;

-- 1. 核心经营指标

SELECT
    COUNT(DISTINCT order_id) AS orders,                    
    COUNT(DISTINCT customer_unique_id) AS customers,      
    ROUND(SUM(merchandise_value), 2) AS gmv,             
    ROUND(AVG(merchandise_value), 2) AS aov,              
    ROUND(AVG(item_lines), 2) AS avg_items_per_order      
FROM vw_order_fact
WHERE order_status = 'delivered';

-- 2. 月度销售趋势

SELECT
    purchase_month,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT customer_unique_id) AS customers,
    ROUND(SUM(merchandise_value), 2) AS gmv,
    ROUND(AVG(merchandise_value), 2) AS aov
FROM vw_order_fact
WHERE order_status = 'delivered'
GROUP BY purchase_month
ORDER BY purchase_month;

-- 月度 GMV 环比分析

WITH monthly_sales AS (

    SELECT
        purchase_month,
        ROUND(SUM(merchandise_value), 2) AS gmv

    FROM vw_order_fact

    WHERE order_status = 'delivered'

    GROUP BY purchase_month
),

monthly_compare AS (

    SELECT
        purchase_month,
        gmv,

        LAG(gmv) OVER (
            ORDER BY purchase_month
        ) AS previous_month_gmv

    FROM monthly_sales
)

SELECT
    purchase_month,
    gmv,
    previous_month_gmv,

    ROUND(
        100.0 * (gmv - previous_month_gmv)
        / NULLIF(previous_month_gmv, 0),
        2
    ) AS mom_growth_pct

FROM monthly_compare

ORDER BY purchase_month;

-- 3. 各州销售表现

SELECT
    COALESCE(customer_state, 'Unknown') AS customer_state,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT customer_unique_id) AS customers,
    ROUND(SUM(merchandise_value), 2) AS gmv,
    ROUND(AVG(merchandise_value), 2) AS aov
FROM vw_order_fact
WHERE order_status = 'delivered'
GROUP BY COALESCE(customer_state, 'Unknown')
ORDER BY gmv DESC;



-- 4. 下单小时分布

SELECT
    purchase_hour,
    COUNT(*) AS orders,
    ROUND(SUM(merchandise_value), 2) AS gmv
FROM vw_order_fact
WHERE order_status = 'delivered'
GROUP BY purchase_hour
ORDER BY purchase_hour;

-- 5. 复购率

SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN customer_orders >= 2 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(
        100.0 * SUM(CASE WHEN customer_orders >= 2 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS repeat_rate_pct
FROM (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS customer_orders
    FROM vw_order_fact
    WHERE order_status = 'delivered'
      AND customer_unique_id IS NOT NULL
    GROUP BY customer_unique_id
) t;

-- 6. RFM 基础表
--
-- R = Recency：距离数据集中最后一天有多少天没购买
-- F = Frequency：购买订单数
-- M = Monetary：累计消费金额


SELECT
    customer_unique_id,

    DATEDIFF(
        (
            SELECT MAX(purchase_date)
            FROM vw_order_fact
            WHERE order_status = 'delivered'
        ),
        MAX(purchase_date)
    ) AS recency_days,

    COUNT(DISTINCT order_id) AS frequency,

    ROUND(SUM(merchandise_value), 2) AS monetary

FROM vw_order_fact
WHERE order_status = 'delivered'
  AND customer_unique_id IS NOT NULL
GROUP BY customer_unique_id
ORDER BY monetary DESC;

-- 7. TOP 10 商品品类

SELECT
    product_category,
    COUNT(*) AS item_lines,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(SUM(price), 2) AS gmv
FROM vw_order_item_fact
WHERE order_status = 'delivered'
GROUP BY product_category
ORDER BY gmv DESC
LIMIT 10;

-- 8. TOP 10 商品

SELECT
    product_id,
    COUNT(*) AS sales_volume,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(SUM(price), 2) AS gmv
FROM vw_order_item_fact
WHERE order_status = 'delivered'
GROUP BY product_id
ORDER BY gmv DESC
LIMIT 10;

-- 9. 配送表现

SELECT
    COUNT(*) AS delivered_orders,
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days,
    SUM(CASE WHEN delivery_status = 'Late' THEN 1 ELSE 0 END) AS late_orders,

    ROUND(
        100.0 * SUM(CASE WHEN delivery_status = 'Late' THEN 1 ELSE 0 END)
        / NULLIF(
            SUM(
                CASE
                    WHEN delivery_status IN ('Late', 'On Time / Early')
                    THEN 1 ELSE 0
                END
            ),
            0
        ),
        2
    ) AS late_rate_pct

FROM vw_order_fact
WHERE order_status = 'delivered'
  AND delivery_days IS NOT NULL;

-- 10. 配送是否延迟 vs 用户评分

SELECT
    delivery_status,
    COUNT(*) AS orders_with_review,
    ROUND(AVG(review_score), 2) AS avg_review_score
FROM vw_order_fact
WHERE order_status = 'delivered'
  AND review_score IS NOT NULL
  AND delivery_status IN ('Late', 'On Time / Early')
GROUP BY delivery_status;

-- 11. 用户评分分布

SELECT
    review_score,
    COUNT(*) AS review_count
FROM vw_clean_reviews
WHERE review_score IS NOT NULL
GROUP BY review_score
ORDER BY review_score;


# E-commerce Sales & Customer Analytics Dashboard

## Project Overview

This project analyzes e-commerce sales, customer behavior, product performance, and delivery operations using SQL and Power BI.

The goal was to transform raw e-commerce data into business insights and build an interactive dashboard that helps understand:

* Overall sales performance
* Customer purchasing behavior
* Customer retention
* Product category performance
* Delivery performance
* The relationship between delivery delays and customer satisfaction

---

## Tools Used

* SQL
* Power BI
* DAX
* Data Modeling
* Data Visualization
* RFM Customer Segmentation

---

## Dashboard Pages

### 1. Executive Overview

The Executive Overview provides a high-level view of business performance.

Key metrics:

* GMV: R$13.22M
* Orders: 96,478
* Customers: 93,358
* Average Order Value: R$137.04
* Repeat Customer Rate: 3.00%

The page also includes:

* Monthly GMV trend
* Monthly order trend
* Top 10 states by GMV
* Top 10 product categories by GMV

---

### 2. Customer Analytics

This page focuses on customer behavior and retention.

Key metrics:

* Customers: 93,358
* Repeat Rate: 3.00%
* Average Purchase Frequency: 1.03
* Average Customer Spend: R$141.62

The analysis includes:

* One-time vs repeat customers
* Purchase frequency distribution
* RFM customer segmentation
* Customer recency
* Customer monetary segments

---

### 3. Product & Operations

This page analyzes product performance and delivery operations.

Key metrics:

* Product GMV: R$13.22M
* Average Delivery Time: 12.50 days
* Late Delivery Rate: 8.11%
* Average Review Score: 4.16

The page also includes:

* Product category contribution to GMV
* Top 10 product categories
* Delivery status distribution
* Review score by delivery status

---

## Key Insights

### 1. Customer retention is low

Only 3.00% of customers are repeat customers, indicating that most customers purchase only once.

This suggests an opportunity to improve customer retention through loyalty programs, targeted promotions, and personalized marketing.

### 2. A large share of customers are inactive

The RFM analysis identified 49,261 customers in the Lost Customers segment.

This represents a major opportunity for customer reactivation campaigns.

### 3. Sales are geographically concentrated

São Paulo (SP) generated approximately R$5.07M in GMV, significantly more than other states.

This shows that revenue is heavily concentrated in the SP market.

### 4. Health & Beauty is a leading product category

The health_beauty category generated approximately R$1.23M in GMV, making it one of the strongest product categories.

### 5. Late delivery is associated with lower customer satisfaction

Customers receiving orders On Time / Early had an average review score of approximately 4.3.

Late deliveries had an average review score of approximately 2.6.

This suggests that improving delivery performance could have a significant positive impact on customer satisfaction.

---

## Business Recommendations

Based on the analysis:

* Develop retention campaigns for first-time customers.
* Create reactivation campaigns for lost customers.
* Prioritize high-performing product categories.
* Continue investing in strong geographic markets such as São Paulo.
* Reduce late deliveries to improve customer review scores.
* Monitor delivery performance as a key customer experience metric.

---

## Project Structure

```text
Ecommerce_Analytics_Project
│
├── dashboard
│   └── Ecommerce_Analytics_Dashboard.pbix
│
├── screenshots
│   ├── 01_Executive_Overview.png
│   ├── 02_Customer_Analytics.png
│   └── 03_Product_Operations.png
│
├── sql
│   └── SQL files
│
└── README.md
```
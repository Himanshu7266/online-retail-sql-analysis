/*
-------------------------------------------------------
 File: 04_analysis.sql
 Purpose:
  - Business analysis queries on Online Retail data
-------------------------------------------------------
*/

USE online_retail;

-- TOTAL REVENUE
SELECT ROUND(SUM(od.Quantity * p.UnitPrice), 2) AS total_revenue
FROM order_details od
JOIN products p ON od.StockCode = p.StockCode;

-- MONTHLY REVENUE TREND
SELECT DATE_FORMAT(o.InvoiceDate, '%Y-%m') AS month,
       ROUND(SUM(od.Quantity * p.UnitPrice), 2) AS revenue
FROM orders o
JOIN order_details od ON o.InvoiceNo = od.InvoiceNo
JOIN products p ON od.StockCode = p.StockCode
GROUP BY month
ORDER BY month;

-- TOP 10 CUSTOMERS BY SPENDING
SELECT o.CustomerID,
       ROUND(SUM(od.Quantity * p.UnitPrice), 2) AS total_spent
FROM orders o
JOIN order_details od ON o.InvoiceNo = od.InvoiceNo
JOIN products p ON od.StockCode = p.StockCode
GROUP BY o.CustomerID
ORDER BY total_spent DESC
LIMIT 10;

-- TOP 10 PRODUCTS BY REVENUE
SELECT p.StockCode,
       p.Description,
       ROUND(SUM(od.Quantity * p.UnitPrice), 2) AS revenue
FROM order_details od
JOIN products p ON od.StockCode = p.StockCode
GROUP BY p.StockCode, p.Description
ORDER BY revenue DESC
LIMIT 10;

-- COUNTRY WISE REVENUE
SELECT c.Country,
       ROUND(SUM(od.Quantity * p.UnitPrice), 2) AS revenue
FROM customers c
JOIN orders o ON c.CustomerID = o.CustomerID
JOIN order_details od ON o.InvoiceNo = od.InvoiceNo
JOIN products p ON od.StockCode = p.StockCode
GROUP BY c.Country
ORDER BY revenue DESC;

-- AVERAGE ORDER VALUE
SELECT ROUND(
  (SELECT SUM(od.Quantity * p.UnitPrice)
   FROM order_details od
   JOIN products p ON od.StockCode = p.StockCode) /
  (SELECT COUNT(*) FROM orders)
, 2) AS avg_order_value;

-- REPEAT VS ONE-TIME CUSTOMERS
SELECT
  CASE WHEN order_count > 1 THEN 'Repeat' ELSE 'One-Time' END AS customer_type,
  COUNT(*) AS customers
FROM (
  SELECT CustomerID, COUNT(*) AS order_count
  FROM orders
  GROUP BY CustomerID
) t
GROUP BY customer_type;

-- PEAK SALES (DAY-WISE)
SELECT DAYNAME(o.InvoiceDate) AS day_name,
       ROUND(SUM(od.Quantity * p.UnitPrice), 2) AS revenue
FROM orders o
JOIN order_details od ON o.InvoiceNo = od.InvoiceNo
JOIN products p ON od.StockCode = p.StockCode
GROUP BY day_name
ORDER BY revenue DESC;

-- PEAK SALES (HOUR-WISE)
SELECT HOUR(o.InvoiceDate) AS sales_hour,
       ROUND(SUM(od.Quantity * p.UnitPrice), 2) AS revenue
FROM orders o
JOIN order_details od ON o.InvoiceNo = od.InvoiceNo
JOIN products p ON od.StockCode = p.StockCode
GROUP BY sales_hour
ORDER BY revenue DESC;

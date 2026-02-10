/*
-------------------------------------------------------
 File: 03_load.sql
 Purpose:
  - Load cleaned data from retail_clean into normalized tables
-------------------------------------------------------
*/

USE online_retail;

-- Customers
INSERT IGNORE INTO customers (CustomerID, Country)
SELECT DISTINCT CustomerID, Country
FROM retail_clean;

-- Products
INSERT IGNORE INTO products (StockCode, Description, UnitPrice)
SELECT DISTINCT StockCode, Description, UnitPrice
FROM retail_clean;

-- Orders
INSERT IGNORE INTO orders (InvoiceNo, CustomerID, InvoiceDate)
SELECT DISTINCT InvoiceNo, CustomerID, InvoiceDate
FROM retail_clean;

-- Order Details
INSERT IGNORE INTO order_details (InvoiceNo, StockCode, Quantity)
SELECT DISTINCT InvoiceNo, StockCode, Quantity
FROM retail_clean;

-- Sanity check
SELECT COUNT(*) AS customers_rows FROM customers;
SELECT COUNT(*) AS orders_rows    FROM orders;
SELECT COUNT(*) AS details_rows   FROM order_details;

-- Join sample preview
SELECT o.InvoiceNo, c.CustomerID, p.Description, od.Quantity
FROM order_details od
JOIN orders o    ON od.InvoiceNo = o.InvoiceNo
JOIN customers c ON o.CustomerID = c.CustomerID
JOIN products p  ON od.StockCode = p.StockCode
LIMIT 10;

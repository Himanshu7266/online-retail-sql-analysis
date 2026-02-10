
/*
-------------------------------------------------------
 Purpose:
  - Create database
  - Create RAW staging table (online_retail_raw)
  - Create normalized schema tables:
    customers, products, orders, order_details
-------------------------------------------------------
*/

CREATE DATABASE IF NOT EXISTS online_retail;
USE online_retail;

-- RAW table (CSV import target)
DROP TABLE IF EXISTS online_retail_raw;

CREATE TABLE online_retail_raw (
  InvoiceNo   VARCHAR(20),
  StockCode   VARCHAR(20),
  Description VARCHAR(255),
  Quantity    INT,
  InvoiceDate VARCHAR(30),
  UnitPrice   DECIMAL(10,2),
  CustomerID  INT,
  Country     VARCHAR(60)
);

-- Final normalized tables
DROP TABLE IF EXISTS order_details;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
  CustomerID INT PRIMARY KEY,
  Country    VARCHAR(60)
);

CREATE TABLE products (
  StockCode    VARCHAR(20) PRIMARY KEY,
  Description  VARCHAR(255),
  UnitPrice    DECIMAL(10,2)
);

CREATE TABLE orders (
  InvoiceNo    VARCHAR(20) PRIMARY KEY,
  CustomerID   INT NOT NULL,
  InvoiceDate  DATETIME NOT NULL,
  CONSTRAINT fk_orders_customer
    FOREIGN KEY (CustomerID) REFERENCES customers(CustomerID)
);

CREATE TABLE order_details (
  InvoiceNo VARCHAR(20) NOT NULL,
  StockCode VARCHAR(20) NOT NULL,
  Quantity  INT NOT NULL,
  PRIMARY KEY (InvoiceNo, StockCode),
  CONSTRAINT fk_od_orders
    FOREIGN KEY (InvoiceNo) REFERENCES orders(InvoiceNo),
  CONSTRAINT fk_od_products
    FOREIGN KEY (StockCode) REFERENCES products(StockCode)
);


/*
-------------------------------------------------------
 File: 02_cleaning.sql
 Purpose:
  - Clean raw data from online_retail_raw
  - Create cleaned staging table retail_clean
-------------------------------------------------------
 Assumptions:
  - InvoiceDate is in ISO format: 'YYYY-MM-DD HH:MM:SS'
-------------------------------------------------------
*/

DROP TABLE IF EXISTS retail_clean;

CREATE TABLE retail_clean AS
SELECT DISTINCT
  InvoiceNo,
  StockCode,
  Description,
  Quantity,
  STR_TO_DATE(TRIM(InvoiceDate), '%Y-%m-%d %H:%i:%s') AS InvoiceDate,
  UnitPrice,
  CustomerID,
  Country
FROM online_retail_raw
WHERE CustomerID IS NOT NULL
  AND CustomerID > 0
  AND Quantity > 0
  AND UnitPrice > 0
  AND InvoiceNo NOT LIKE 'C%'
  AND Description IS NOT NULL
  AND TRIM(Description) <> ''
  AND STR_TO_DATE(TRIM(InvoiceDate), '%Y-%m-%d %H:%i:%s') IS NOT NULL
  AND Quantity < 10000
  AND UnitPrice < 10000;

-- Quick validation
SELECT COUNT(*) AS raw_rows   FROM online_retail_raw;
SELECT COUNT(*) AS clean_rows FROM retail_clean;
SELECT * FROM retail_clean LIMIT 5;

/*
-------------------------------------------------------
 File: 03_load.sql
 Purpose:
  - Load cleaned data from retail_clean into normalized tables
-------------------------------------------------------
*/

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


/*
-------------------------------------------------------
 File: 04_analysis.sql
 Purpose:
  - Business analysis queries
-------------------------------------------------------
*/

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

-- TOP 10 CUSTOMERS
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

/*
-------------------------------------------------------
 File: 05_advanced.sql
 Purpose:
  - Advanced SQL features:
    View, Stored Procedure, Trigger, Indexing
-------------------------------------------------------
*/

-- VIEW (Reusable monthly revenue)
DROP VIEW IF EXISTS monthly_revenue;

CREATE VIEW monthly_revenue AS
SELECT DATE_FORMAT(o.InvoiceDate, '%Y-%m') AS month,
       ROUND(SUM(od.Quantity * p.UnitPrice), 2) AS revenue
FROM orders o
JOIN order_details od ON o.InvoiceNo = od.InvoiceNo
JOIN products p ON od.StockCode = p.StockCode
GROUP BY month;

-- STORED PROCEDURE: Top N customers
DROP PROCEDURE IF EXISTS top_customers;

DELIMITER //
CREATE PROCEDURE top_customers(IN n INT)
BEGIN
  SELECT o.CustomerID,
         ROUND(SUM(od.Quantity * p.UnitPrice), 2) AS total_spent
  FROM orders o
  JOIN order_details od ON o.InvoiceNo = od.InvoiceNo
  JOIN products p ON od.StockCode = p.StockCode
  GROUP BY o.CustomerID
  ORDER BY total_spent DESC
  LIMIT n;
END //
DELIMITER ;

-- TRIGGER: Prevent invalid quantity inserts
DROP TRIGGER IF EXISTS prevent_negative_quantity;

DELIMITER //
CREATE TRIGGER prevent_negative_quantity
BEFORE INSERT ON order_details
FOR EACH ROW
BEGIN
  IF NEW.Quantity <= 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Quantity must be positive';
  END IF;
END //
DELIMITER ;

-- INDEXING (Performance Optimization)
CREATE INDEX idx_orders_customer     ON orders(CustomerID);
CREATE INDEX idx_orders_date         ON orders(InvoiceDate);
CREATE INDEX idx_orderdetails_stock  ON order_details(StockCode);
CREATE INDEX idx_customers_country   ON customers(Country);

-- Quick check
SHOW TRIGGERS;
SHOW INDEX FROM orders;
SHOW INDEX FROM order_details;
SHOW INDEX FROM customers;


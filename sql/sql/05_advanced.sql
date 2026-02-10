/*
-------------------------------------------------------
 File: 05_advanced.sql
 Purpose:
  - Advanced SQL features
  - View, Stored Procedure, Trigger, Indexes
-------------------------------------------------------
*/

USE online_retail;

-- VIEW: Monthly Revenue (Reusable)
DROP VIEW IF EXISTS monthly_revenue;

CREATE VIEW monthly_revenue AS
SELECT DATE_FORMAT(o.InvoiceDate, '%Y-%m') AS month,
       ROUND(SUM(od.Quantity * p.UnitPrice), 2) AS revenue
FROM orders o
JOIN order_details od ON o.InvoiceNo = od.InvoiceNo
JOIN products p ON od.StockCode = p.StockCode
GROUP BY month;

-- STORED PROCEDURE: Top N Customers
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

-- TRIGGER: Prevent Invalid Quantity
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

-- INDEXING: Performance Optimization
CREATE INDEX idx_orders_customer ON orders(CustomerID);
CREATE INDEX idx_orders_date ON orders(InvoiceDate);
CREATE INDEX idx_orderdetails_stock ON order_details(StockCode);
CREATE INDEX idx_customers_country ON customers(Country);

-- Verification
SHOW VIEWS;
SHOW TRIGGERS;
SHOW INDEX FROM orders;

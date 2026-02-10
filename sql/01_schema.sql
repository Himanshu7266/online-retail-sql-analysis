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

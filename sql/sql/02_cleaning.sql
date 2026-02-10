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

USE online_retail;

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

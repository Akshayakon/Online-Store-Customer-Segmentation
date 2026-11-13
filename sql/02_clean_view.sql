-- 02_clean_view.sql
-- Cleaned transactions: real purchases made by identified customers.
DROP VIEW IF EXISTS clean_sales;
CREATE VIEW clean_sales AS
SELECT
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    DATE(InvoiceDate)            AS invoice_date,
    UnitPrice,
    CAST(CAST(CustomerID AS INTEGER) AS TEXT) AS customer_id,
    Country,
    Quantity * UnitPrice         AS line_total
FROM online_retail_raw
WHERE CustomerID IS NOT NULL
  AND InvoiceNo NOT LIKE 'C%'
  AND Quantity  > 0
  AND UnitPrice > 0;

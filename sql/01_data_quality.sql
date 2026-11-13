-- 01_data_quality.sql
-- Profile the raw table `online_retail_raw` and justify the cleaning rules.
-- Columns: InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country

-- 1) Overall size using COUNT DISTINCT
SELECT
    COUNT(*)                          AS total_rows,
    COUNT(DISTINCT InvoiceNo)         AS distinct_invoices,
    COUNT(DISTINCT CustomerID)        AS distinct_customers,
    COUNT(DISTINCT StockCode)         AS distinct_products,
    COUNT(DISTINCT Country)           AS distinct_countries,
    MIN(InvoiceDate)                  AS first_invoice,
    MAX(InvoiceDate)                  AS last_invoice
FROM online_retail_raw;

-- 2) Rows we must exclude, and why
SELECT
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END)           AS missing_customer,
    SUM(CASE WHEN InvoiceNo LIKE 'C%' THEN 1 ELSE 0 END)          AS cancellations,
    SUM(CASE WHEN Quantity <= 0 THEN 1 ELSE 0 END)                AS non_positive_qty,
    SUM(CASE WHEN UnitPrice <= 0 THEN 1 ELSE 0 END)               AS non_positive_price
FROM online_retail_raw;

-- 3) Share of rows retained after cleaning
SELECT
    ROUND(100.0 * SUM(CASE WHEN CustomerID IS NOT NULL
                            AND InvoiceNo NOT LIKE 'C%'
                            AND Quantity > 0 AND UnitPrice > 0 THEN 1 ELSE 0 END) / COUNT(*), 1)
        AS pct_rows_retained
FROM online_retail_raw;

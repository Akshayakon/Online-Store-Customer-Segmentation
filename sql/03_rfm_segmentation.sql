-- 03_rfm_segmentation.sql
-- RFM segmentation with CTEs. Creates table `rfm_segments`.
--   Recency   = days between the snapshot date and the customer's last purchase (lower is better)
--   Frequency = COUNT(DISTINCT InvoiceNo)  (number of orders)
--   Monetary  = SUM(Quantity * UnitPrice)
-- Scores are 1-5 quintiles via NTILE(5); 5 is always best.

DROP TABLE IF EXISTS rfm_segments;
CREATE TABLE rfm_segments AS
WITH snapshot AS (
    -- Day after the last transaction, so the most recent buyer has recency = 1
    SELECT DATE(MAX(invoice_date), '+1 day') AS snapshot_date
    FROM clean_sales
),
rfm_base AS (
    SELECT
        c.customer_id,
        MAX(c.country)                                          AS country,
        CAST(julianday(s.snapshot_date) - julianday(MAX(c.invoice_date)) AS INTEGER) AS recency_days,
        COUNT(DISTINCT c.InvoiceNo)                             AS frequency,
        ROUND(SUM(c.line_total), 2)                             AS monetary
    FROM clean_sales c
    CROSS JOIN snapshot s
    GROUP BY c.customer_id
),
rfm_scored AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency_days DESC)              AS r_score,  -- recent = 5
        -- Frequency has heavy ties (many one-time buyers), so rank by frequency then monetary
        NTILE(5) OVER (ORDER BY frequency ASC, monetary ASC)    AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)                   AS m_score
    FROM rfm_base
)
SELECT
    *,
    CAST(r_score AS TEXT) || f_score || m_score                 AS rfm_code,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 4                  THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score BETWEEN 2 AND 3       THEN 'Potential Loyalists'
        WHEN r_score >= 4 AND f_score = 1                   THEN 'New Customers'
        WHEN r_score = 3  AND f_score <= 3                  THEN 'Need Attention'
        WHEN r_score <= 2 AND f_score >= 4                  THEN 'Cant Lose Them'
        WHEN r_score <= 2 AND f_score >= 2                  THEN 'At Risk'
        ELSE 'Hibernating / Lost'
    END                                                         AS segment
FROM rfm_scored;

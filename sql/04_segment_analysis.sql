-- 04_segment_analysis.sql
-- Business-facing summaries of the `rfm_segments` table.

-- Q1. Segment size, behaviour and revenue contribution
WITH totals AS (
    SELECT COUNT(*) AS n_customers, SUM(monetary) AS total_revenue FROM rfm_segments
)
SELECT
    r.segment,
    COUNT(DISTINCT r.customer_id)                               AS customers,
    ROUND(100.0 * COUNT(*) / t.n_customers, 1)                  AS pct_customers,
    ROUND(AVG(r.recency_days), 1)                               AS avg_recency_days,
    ROUND(AVG(r.frequency), 1)                                  AS avg_orders,
    ROUND(AVG(r.monetary), 0)                                   AS avg_spend,
    ROUND(SUM(r.monetary), 0)                                   AS revenue,
    ROUND(100.0 * SUM(r.monetary) / t.total_revenue, 1)         AS pct_revenue
FROM rfm_segments r
CROSS JOIN totals t
GROUP BY r.segment, t.n_customers, t.total_revenue
ORDER BY revenue DESC;

-- Q2. Top 10 countries by customers and revenue (with segment mix of Champions)
WITH country_stats AS (
    SELECT
        country,
        COUNT(DISTINCT customer_id)                             AS customers,
        ROUND(SUM(monetary), 0)                                 AS revenue,
        COUNT(DISTINCT CASE WHEN segment = 'Champions' THEN customer_id END) AS champions
    FROM rfm_segments
    GROUP BY country
)
SELECT * FROM country_stats ORDER BY revenue DESC LIMIT 10;

-- Q3. Repeat vs one-time buyers
SELECT
    CASE WHEN frequency = 1 THEN 'One-time' ELSE 'Repeat' END   AS buyer_type,
    COUNT(DISTINCT customer_id)                                 AS customers,
    ROUND(SUM(monetary), 0)                                     AS revenue
FROM rfm_segments
GROUP BY buyer_type;

-- Q4. Monthly active customers and revenue
SELECT
    STRFTIME('%Y-%m', invoice_date)                             AS month,
    COUNT(DISTINCT customer_id)                                 AS active_customers,
    COUNT(DISTINCT InvoiceNo)                                   AS orders,
    ROUND(SUM(line_total), 0)                                   AS revenue
FROM clean_sales
GROUP BY month
ORDER BY month;

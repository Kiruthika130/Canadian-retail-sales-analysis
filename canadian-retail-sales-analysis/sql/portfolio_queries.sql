-- Question: Which provinces had the most retail sales
-- in the latest complete year?
-- Source: reported province-level retail totals, in CAD millions.

WITH province_year_coverage AS (
    SELECT
        d.year,
        f.province_id,
        COUNT(DISTINCT d.month) AS months_covered
    FROM fact_province_total AS f
    JOIN dim_date AS d
        ON d.date_key = f.date_key
    GROUP BY d.year, f.province_id
),
complete_years AS (
    SELECT year
    FROM province_year_coverage
    GROUP BY year
    HAVING COUNT(*) = (SELECT COUNT(*) FROM dim_province)
       AND MIN(months_covered) = 12
),
latest_complete_year AS (
    SELECT MAX(year) AS year
    FROM complete_years
),
annual_province_sales AS (
    SELECT
        p.province_name,
        p.region,
        d.year,
        SUM(f.reported_total_millions) AS sales_millions
    FROM fact_province_total AS f
    JOIN dim_date AS d
        ON d.date_key = f.date_key
    JOIN dim_province AS p
        ON p.province_id = f.province_id
    WHERE d.year = (SELECT year FROM latest_complete_year)
    GROUP BY p.province_name, p.region, d.year
)
SELECT
    province_name,
    region,
    year,
    ROUND(sales_millions, 0) AS sales_millions,
    ROUND(
        100.0 * sales_millions / SUM(sales_millions) OVER (),
        1
    ) AS share_of_total_pct,
    RANK() OVER (ORDER BY sales_millions DESC) AS sales_rank
FROM annual_province_sales
ORDER BY sales_rank;
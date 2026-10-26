WITH dates AS (
    SELECT * FROM {{ ref('dim_date') }}
    WHERE date <= {{ get_max_reporting_date() }}
),

weeks AS (
    SELECT DISTINCT week_name, week_start_date, week_end_date FROM dates
),

months AS (
    SELECT DISTINCT month_name, month_start_date, month_end_date FROM dates
),

quarters AS (
    SELECT DISTINCT quarter_name, quarter_start_date, quarter_end_date FROM dates
),

years AS (
    SELECT DISTINCT fiscal_year_name, fiscal_year_start_date, fiscal_year_end_date FROM dates
),

-- Calendar buckets: one row per period, till_date is NULL
week AS (
    SELECT 'WEEK' AS bucket_type, week_name AS bucket_name,
           week_start_date AS bucket_start_date, week_end_date AS bucket_end_date,
           NULL::DATE AS till_date
    FROM weeks
),

month AS (
    SELECT 'MONTH', month_name, month_start_date, month_end_date, NULL::DATE
    FROM months
),

quarter AS (
    SELECT 'QUARTER', quarter_name, quarter_start_date, quarter_end_date, NULL::DATE
    FROM quarters
),

year AS (
    SELECT 'YEAR', fiscal_year_name, fiscal_year_start_date, fiscal_year_end_date, NULL::DATE
    FROM years
),

-- Rolling windows: one row per week, anchored on the week's end date (till_date)
r4w AS (
    SELECT 'R4W', 'R4W-' || week_name, DATEADD(DAY, -21, week_start_date), week_end_date, week_end_date
    FROM weeks
),

r13w AS (
    SELECT 'R13W', 'R13W-' || week_name, DATEADD(DAY, -84, week_start_date), week_end_date, week_end_date
    FROM weeks
),

r26w AS (
    SELECT 'R26W', 'R26W-' || week_name, DATEADD(DAY, -175, week_start_date), week_end_date, week_end_date
    FROM weeks
),

r52w AS (
    SELECT 'R52W', 'R52W-' || week_name, DATEADD(DAY, -357, week_start_date), week_end_date, week_end_date
    FROM weeks
),

-- To-date windows: one row per day
wtd AS (
    SELECT 'WTD', 'WTD-' || TO_CHAR(date, 'YYYY-MM-DD'), week_start_date, date, date
    FROM dates
),

mtd AS (
    SELECT 'MTD', 'MTD-' || TO_CHAR(date, 'YYYY-MM-DD'), month_start_date, date, date
    FROM dates
),

qtd AS (
    SELECT 'QTD', 'QTD-' || TO_CHAR(date, 'YYYY-MM-DD'), quarter_start_date, date, date
    FROM dates
),

ytd AS (
    SELECT 'YTD', 'YTD-' || TO_CHAR(date, 'YYYY-MM-DD'), fiscal_year_start_date, date, date
    FROM dates
),

buckets AS (
    SELECT * FROM week    UNION ALL
    SELECT * FROM month   UNION ALL
    SELECT * FROM quarter UNION ALL
    SELECT * FROM year    UNION ALL
    SELECT * FROM r4w     UNION ALL
    SELECT * FROM r13w    UNION ALL
    SELECT * FROM r26w    UNION ALL
    SELECT * FROM r52w    UNION ALL
    SELECT * FROM wtd     UNION ALL
    SELECT * FROM mtd     UNION ALL
    SELECT * FROM qtd     UNION ALL
    SELECT * FROM ytd
),

reporting_limit AS (
    SELECT {{ get_max_reporting_date() }} AS max_reporting_date
)

SELECT
    b.bucket_type,
    b.bucket_name,
    b.bucket_start_date,
    LEAST(
        b.bucket_end_date,
        r.max_reporting_date
    ) AS bucket_end_date,
    b.till_date
FROM buckets b
CROSS JOIN reporting_limit r
WHERE b.bucket_start_date <= r.max_reporting_date
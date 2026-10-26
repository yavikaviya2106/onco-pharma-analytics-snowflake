{# Week = Saturday..Friday (pharma-style). Session-independent: anchored to a known Saturday.
   Override with --vars '{week_anchor: "1900-01-01"}' for Monday-start weeks. #}

WITH date_spine AS (
    {{
        dbt_utils.date_spine(
            datepart   = 'day',
            start_date = "cast('2021-01-01' as date)",
            end_date   = "cast('2031-01-01' as date)"
        )
    }}
),

date_base AS (
    SELECT
        CAST(date_day AS DATE)                                        AS date_day,
        DATEADD(
            DAY,
            -MOD(DATEDIFF(DAY, '{{ var("week_anchor", "1900-01-06") }}'::DATE, CAST(date_day AS DATE)), 7),
            CAST(date_day AS DATE)
        )                                                             AS week_start_date
    FROM date_spine
),

date_ranges AS (
    SELECT
        date_day,
        week_start_date,
        DATEADD(DAY, 6, week_start_date)                              AS week_end_date,
        DATE_TRUNC('MONTH',   date_day)                               AS month_start_date,
        LAST_DAY(date_day, 'MONTH')                                   AS month_end_date,
        DATE_TRUNC('QUARTER', date_day)                               AS quarter_start_date,
        LAST_DAY(date_day, 'QUARTER')                                 AS quarter_end_date,
        DATE_TRUNC('YEAR',    date_day)                               AS year_start_date,
        LAST_DAY(date_day, 'YEAR')                                    AS year_end_date
    FROM date_base
),

date_final AS (
    SELECT
        date_day                                                      AS date,

        DAYOFWEEK(date_day)                                           AS day_of_week,
        DAYNAME(date_day)                                             AS day_name,
        DAY(date_day)                                                 AS day_of_month,
        DAYOFYEAR(date_day)                                           AS day_of_year,

        -- ISO week of the week's END date (unique per week, no year-boundary collisions)
        WEEKISO(week_end_date)                                        AS week_number,
        YEAROFWEEKISO(week_end_date)                                  AS week_year,
        'WK' || LPAD(WEEKISO(week_end_date)::VARCHAR, 2, '0')
            || '-' || YEAROFWEEKISO(week_end_date)::VARCHAR           AS week_name,
        week_start_date,
        week_end_date,

        MONTH(date_day)                                               AS month_number,
        TO_CHAR(date_day, 'Mon-YYYY')                                 AS month_name,
        month_start_date,
        month_end_date,

        QUARTER(date_day)                                             AS quarter_number,
        'Q' || QUARTER(date_day)::VARCHAR
            || '-' || YEAR(date_day)::VARCHAR                         AS quarter_name,
        quarter_start_date,
        quarter_end_date,

        YEAR(date_day)                                                AS fiscal_year,
        'FY-' || YEAR(date_day)::VARCHAR                              AS fiscal_year_name,
        year_start_date                                               AS fiscal_year_start_date,
        year_end_date                                                 AS fiscal_year_end_date,

        -- TODO: replace with a holiday seed (Thanksgiving, Memorial Day, etc.)
        CASE
            WHEN MONTH(date_day) = 1  AND DAY(date_day) = 1  THEN TRUE
            WHEN MONTH(date_day) = 7  AND DAY(date_day) = 4  THEN TRUE
            WHEN MONTH(date_day) = 11 AND DAY(date_day) = 11 THEN TRUE
            WHEN MONTH(date_day) = 12 AND DAY(date_day) = 25 THEN TRUE
            ELSE FALSE
        END                                                           AS holiday_flag,

        CASE
            WHEN MONTH(date_day) = 1  AND DAY(date_day) = 1  THEN 'New Years Day'
            WHEN MONTH(date_day) = 7  AND DAY(date_day) = 4  THEN 'Independence Day'
            WHEN MONTH(date_day) = 11 AND DAY(date_day) = 11 THEN 'Veterans Day'
            WHEN MONTH(date_day) = 12 AND DAY(date_day) = 25 THEN 'Christmas Day'
            ELSE NULL
        END                                                           AS holiday_name
    FROM date_ranges
)

SELECT * FROM date_final
WITH base AS (
    SELECT * FROM {{ ref('unified_model') }}
),

aggregated AS (
    SELECT
        date,
        source,

        sum(impressions)                                        AS impressions,
        sum(clicks)                                             AS clicks,
        sum(cost)                                               AS cost,
        sum(conversions)                                        AS conversions,
        sum(conversion_value)                                   AS conversion_value,
        sum(reach)                                              AS reach,
        sum(video_views)                                        AS video_views,
        sum(video_watch_100)                                    AS video_completions,
        sum(engagement_actions)                                 AS engagement_actions

    FROM base
    GROUP BY date, source
),

with_derived as (
    SELECT
        *,
        CASE WHEN impressions IS NULL OR impressions = 0 THEN NULL ELSE CAST(clicks AS FLOAT64) / impressions END                        AS ctr,
        CASE WHEN clicks IS NULL OR clicks = 0 THEN NULL ELSE CAST(cost AS FLOAT64) / clicks END                                         AS cpc,
        CASE WHEN impressions IS NULL OR impressions = 0 THEN NULL ELSE (CAST(cost AS FLOAT64) / impressions) * 1000 END                 AS cpm,
        CASE WHEN conversions IS NULL OR conversions = 0 THEN NULL ELSE CAST(cost AS FLOAT64) / conversions END                          AS cpa,
        CASE WHEN clicks IS NULL OR clicks = 0 THEN NULL ELSE CAST(conversions AS FLOAT64) / clicks END                                  AS conversion_rate,
        CASE WHEN cost IS NULL OR cost = 0 THEN NULL ELSE CAST(conversion_value AS FLOAT64) / cost END                                   AS roas,
        CASE WHEN video_views IS NULL OR video_views = 0 THEN NULL ELSE CAST(video_completions AS FLOAT64) / video_views END             AS video_completion_rate,
        CASE WHEN impressions IS NULL OR impressions = 0 THEN NULL ELSE CAST(engagement_actions AS FLOAT64) / impressions END            AS social_engagement_rate
    FROM aggregated
),

-- week-over-week and month-over-month using window functions
with_trends AS (
    SELECT
        *,

        -- 7-day rolling averages (smooths day-of-week noise)
        avg(cost)           over (partition by source order by date rows between 6 preceding and current row) AS cost_7d_avg,
        avg(cpa)            over (partition by source order by date rows between 6 preceding and current row) AS cpa_7d_avg,
        avg(ctr)            over (partition by source order by date rows between 6 preceding and current row) AS ctr_7d_avg,
        avg(roas)           over (partition by source order by date rows between 6 preceding and current row) AS roas_7d_avg,

        -- week-over-week delta
        lag(cost, 7)        over (partition by source order by date)    AS cost_wow_prior,
        lag(conversions, 7) over (partition by source order by date)    AS conversions_wow_prior,
        lag(cpa, 7)         over (partition by source order by date)    AS cpa_wow_prior,

        -- month-over-month delta
        lag(cost, 30)       over (partition by source order by date)    AS cost_mom_prior,
        lag(cpa, 30)        over (partition by source order by date)    AS cpa_mom_prior

    FROM with_derived
)

SELECT
    *,
    -- pct change helpers (feed directly into dashboard KPI cards)
    CASE WHEN cost_wow_prior IS NULL OR cost_wow_prior = 0 THEN NULL ELSE CAST(cost - cost_wow_prior AS FLOAT64) / cost_wow_prior END                          AS cost_wow_pct_change,
    CASE WHEN conversions_wow_prior IS NULL OR conversions_wow_prior = 0 THEN NULL ELSE CAST(conversions - conversions_wow_prior AS FLOAT64) / conversions_wow_prior END AS conversions_wow_pct_change,
    CASE WHEN cpa_wow_prior IS NULL OR cpa_wow_prior = 0 THEN NULL ELSE CAST(cpa - cpa_wow_prior AS FLOAT64) / cpa_wow_prior END                              AS cpa_wow_pct_change,
    CASE WHEN cost_mom_prior IS NULL OR cost_mom_prior = 0 THEN NULL ELSE CAST(cost - cost_mom_prior AS FLOAT64) / cost_mom_prior END                          AS cost_mom_pct_change,
    CASE WHEN cpa_mom_prior IS NULL OR cpa_mom_prior = 0 THEN NULL ELSE CAST(cpa - cpa_mom_prior AS FLOAT64) / cpa_mom_prior END                              AS cpa_mom_pct_change

FROM with_trends
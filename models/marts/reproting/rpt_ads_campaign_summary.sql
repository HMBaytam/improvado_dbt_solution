with base  AS (
    SELECT * FROM {{ ref('unified_model') }}
),

aggregated  AS (
    SELECT
        source,
        campaign_id,
        campaign_name,

        -- date range
        min(date) AS first_seen_date,
        max(date) AS last_seen_date,
        count(distinct date) AS active_days,

        -- volume
        sum(impressions) AS total_impressions,
        sum(clicks) AS total_clicks,
        sum(cost) AS total_cost,
        sum(conversions) AS total_conversions,

        -- google revenue
        sum(conversion_value) AS total_conversion_value,

        -- facebook audience
        sum(reach) AS total_reach,

        -- video
        sum(video_views) AS total_video_views,
        sum(video_watch_100) AS total_video_completions,

        -- tiktok social
        sum(engagement_actions) AS total_engagement_actions

    FROM base
    GROUP BY 1, 2, 3
)

SELECT
    *,

    -- derived from aggregates
    safe_divide(total_clicks, total_impressions)             AS ctr,
    safe_divide(total_cost, total_clicks)                    AS cpc,
    safe_divide(total_cost, total_impressions) * 1000        AS cpm,
    safe_divide(total_cost, total_conversions)               AS cpa,
    safe_divide(total_conversions, total_clicks)             AS conversion_rate,
    safe_divide(total_conversion_value, total_cost)          AS roas,
    safe_divide(total_video_completions, total_video_views)  AS video_completion_rate,
    safe_divide(total_cost, active_days)                     AS avg_daily_spend

FROM aggregated
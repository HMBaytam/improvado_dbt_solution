with unioned AS (
    SELECT * FROM {{ ref('stg_facebook_ads') }}
    union all
    SELECT * FROM {{ ref('stg_google_ads') }}
    union all
    SELECT * FROM {{ ref('stg_tiktok_ads') }}
),

with_derived AS (
    SELECT
        -- grain
        date,
        source,
        campaign_id,
        campaign_name,
        ad_group_id,
        ad_group_name,

        -- core metrics
        impressions,
        clicks,
        cost,
        conversions,

        -- derived metrics (cross-platform)
        safe_divide(clicks, impressions) AS ctr,
        safe_divide(cost, clicks) AS cpc,
        safe_divide(cost, conversions) AS cpa,
        safe_divide(conversions, clicks) AS conversion_rate,
        safe_divide(cost, impressions) * 1000 AS cpm,

        -- facebook-specific
        video_views,
        engagement_rate,
        reach,
        frequency,

        -- google-specific
        conversion_value,
        quality_score,
        search_impression_share,
        safe_divide(conversion_value, cost) AS roAS,

        -- tiktok-specific
        video_watch_25,
        video_watch_50,
        video_watch_75,
        video_watch_100,
        likes,
        shares,
        comments,
        coalesce(likes, 0)
            + coalesce(shares, 0)
            + coalesce(comments, 0) AS engagement_actions

    FROM unioned
)

SELECT * FROM with_derived
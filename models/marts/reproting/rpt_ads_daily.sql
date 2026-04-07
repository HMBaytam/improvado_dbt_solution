WITH base  AS (
    SELECT * FROM {{ ref('unified_model') }}
)

SELECT
    -- grain
    date,
    source,
    campaign_id,
    campaign_name,
    ad_group_id,
    ad_group_name,

    -- core spend & volume
    impressions,
    clicks,
    cost,
    conversions,

    -- universal derived metrics
    ctr,
    cpc,
    cpa,
    cpm,
    conversion_rate,

    -- google
    conversion_value,
    roas,
    quality_score,
    search_impression_share,

    -- facebook
    reach,
    frequency,
    engagement_rate,

    -- tiktok + facebook shared
    video_views,
    safe_divide(video_views, impressions)  AS video_view_rate,

    -- tiktok video funnel (completion rates relative to video views)
    video_watch_25,
    video_watch_50,
    video_watch_75,
    video_watch_100,
    safe_divide(video_watch_25, video_views)  AS watch_rate_25,
    safe_divide(video_watch_50, video_views)  AS watch_rate_50,
    safe_divide(video_watch_75, video_views)  AS watch_rate_75,
    safe_divide(video_watch_100, video_views)  AS watch_rate_100,

    -- tiktok social engagement
    likes,
    shares,
    comments,
    engagement_actions,
    safe_divide(engagement_actions, impressions)     AS social_engagement_rate

FROM base
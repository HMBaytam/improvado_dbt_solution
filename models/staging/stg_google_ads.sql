SELECT
    -- unified metrics from all platforms
    date,
    'google' AS source,
    campaign_id,
    campaign_name,
    ad_group_id,
    ad_group_name,
    impressions,
    clicks,
    cost,
    conversions,

    -- facebook-specific (null)
    null AS video_views,
    null AS engagement_rate,
    null AS reach,
    null AS frequency,

    -- google-specific
    conversion_value,
    quality_score,
    search_impression_share,

    -- tiktok-specific (null)
    null AS video_watch_25,
    null AS video_watch_50,
    null AS video_watch_75,
    null AS video_watch_100,
    null AS likes,
    null AS shares,
    null AS comments

FROM
    {{ source('raw', 'google_ads') }}
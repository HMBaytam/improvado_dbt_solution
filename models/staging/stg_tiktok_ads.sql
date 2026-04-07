SELECT
    -- unified metrics from all platforms
    date,
    'tiktok'  AS source,
    campaign_id,
    campaign_name,
    adgroup_id AS ad_group_id,
    adgroup_name AS ad_group_name,
    impressions,
    clicks,
    cost,
    conversions,

    -- facebook-specific (null)
    video_views,        -- tiktok also hAS this, so pASs through
    null AS engagement_rate,
    null AS reach,
    null AS frequency,

    -- google-specific (null)
    null AS conversion_value,
    null AS quality_score,
    null AS search_impression_share,

    -- tiktok-specific
    video_watch_25,
    video_watch_50,
    video_watch_75,
    video_watch_100,
    likes,
    shares,
    comments
    
FROM
    {{ source('raw', 'tiktok_ads') }}
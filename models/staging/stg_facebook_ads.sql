SELECT
    -- unified metrics from all platforms
    date,
    'facebook' AS source,
    campaign_id,
    campaign_name,
    ad_set_id AS ad_group_id,
    ad_set_name AS ad_group_name,
    impressions,
    clicks,
    spend AS cost,
    conversions,

    -- facebook-specific
    video_views,
    engagement_rate,
    reach,
    frequency,

    -- google-specific (null)
    null AS conversion_value,
    null AS quality_score,
    null AS search_impression_share,

    -- tiktok-specific (null)
    null AS video_watch_25,
    null AS video_watch_50,
    null AS video_watch_75,
    null AS video_watch_100,
    null AS likes,
    null AS shares,
    null AS comments

FROM
    {{ source('raw', 'facebook_ads') }}
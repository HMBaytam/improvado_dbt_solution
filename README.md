# Looker Studio Dashboard Definitions

[Dashboard](https://lookerstudio.google.com/u/1/reporting/61577802-bc4f-4903-b8fd-62ae6bd937ba/page/p_n33chz9i2d)



# Paid Ads dbt Data Layer — Dashboard Context

This document describes the full dbt data layer built for a cross-platform paid ads reporting dashboard. Use it as context when building the dashboard. All tables are materialized as physical tables in the warehouse.

---

## Project Overview

**Data sources:** Facebook Ads, Google Ads, TikTok Ads
**Date range in data:** 2024-01-01 onwards (110 rows per platform)
**Warehouse dialect:** BigQuery (`safe_divide` used for division — swap with `nullif` for Postgres/DuckDB)
**Grain of raw data:** date + campaign_id + ad_group_id (one row per ad group per day)

---

## Architecture / Lineage

```
raw sources (3 tables)
    ↓
stg_facebook_ads  stg_google_ads  stg_tiktok_ads   ← views
    ↓                   ↓               ↓
             unified_model             ← table (mart)
         ↙          ↓           ↘
rpt_ads_daily  rpt_ads_campaign_summary  rpt_ads_platform_summary  ← tables (reporting)
```

**Materialization strategy:**
- `staging/*` → views (always fresh, no storage cost)
- `marts/ unified_model` → table
- `marts/reporting/rpt_*` → tables (optimized for dashboard query speed)

---

## Staging Models (views)

These are internal transformation models. The dashboard does not query these directly.

### `stg_facebook_ads`
Standardizes Facebook raw data to the shared schema. Key transformations:
- `spend` renamed to `cost`
- `ad_set_id` / `ad_set_name` renamed to `ad_group_id` / `ad_group_name`
- Adds `source = 'facebook'`
- Google and TikTok platform-specific columns set to `null`

### `stg_google_ads`
Standardizes Google raw data. Key transformations:
- `ad_group_id` / `ad_group_name` kept as-is (Google naming matches the standard)
- Adds `source = 'google'`
- Facebook and TikTok platform-specific columns set to `null`

### `stg_tiktok_ads`
Standardizes TikTok raw data. Key transformations:
- `adgroup_id` / `adgroup_name` renamed to `ad_group_id` / `ad_group_name`
- Adds `source = 'tiktok'`
- Facebook and Google platform-specific columns set to `null`
- `video_views` passed through (TikTok and Facebook both have this field)

---

## Mart Model

### ` unified_model`

**Grain:** date + source + campaign_id + ad_group_id

The canonical cross-platform table. All three platforms unioned with standardized columns and derived metrics calculated. This is the source for all reporting tables.

| Column | Type | Description | Platforms |
|--------|------|-------------|-----------|
| `date` | date | Report date | All |
| `source` | string | Platform: `facebook`, `google`, `tiktok` | All |
| `campaign_id` | string | Platform-native campaign ID | All |
| `campaign_name` | string | Campaign name | All |
| `ad_group_id` | string | Ad group / ad set / adgroup ID (standardized name) | All |
| `ad_group_name` | string | Ad group / ad set / adgroup name (standardized name) | All |
| `impressions` | int | Total impressions served | All |
| `clicks` | int | Total clicks | All |
| `cost` | float | Spend in account currency | All |
| `conversions` | int | Total conversions | All |
| `ctr` | float | clicks / impressions | All |
| `cpc` | float | cost / clicks | All |
| `cpa` | float | cost / conversions | All |
| `cpm` | float | cost / impressions × 1000 | All |
| `conversion_rate` | float | conversions / clicks | All |
| `video_views` | int | Video views | Facebook, TikTok |
| `video_view_rate` | float | video_views / impressions | Facebook, TikTok |
| `engagement_rate` | float | Native engagement rate from Facebook | Facebook only |
| `reach` | int | Unique users reached | Facebook only |
| `frequency` | float | Average times a user saw the ad | Facebook only |
| `conversion_value` | float | Revenue value of conversions | Google only |
| `quality_score` | int | Google quality score (1–10) | Google only |
| `search_impression_share` | float | Share of eligible impressions captured | Google only |
| `roas` | float | conversion_value / cost | Google only |
| `video_watch_25` | int | Users who watched 25% of video | TikTok only |
| `video_watch_50` | int | Users who watched 50% of video | TikTok only |
| `video_watch_75` | int | Users who watched 75% of video | TikTok only |
| `video_watch_100` | int | Users who watched 100% of video (completions) | TikTok only |
| `likes` | int | Post likes | TikTok only |
| `shares` | int | Post shares | TikTok only |
| `comments` | int | Post comments | TikTok only |
| `engagement_actions` | int | likes + shares + comments | TikTok only |
| `social_engagement_rate` | float | engagement_actions / impressions | TikTok only |
| `watch_rate_25` | float | video_watch_25 / video_views | TikTok only |
| `watch_rate_50` | float | video_watch_50 / video_views | TikTok only |
| `watch_rate_75` | float | video_watch_75 / video_views | TikTok only |
| `watch_rate_100` | float | video_watch_100 / video_views | TikTok only |

**Null behaviour:** Platform-specific columns are `null` on rows from other platforms. Always filter by `source` when using platform-specific columns.

---

## Reporting Models

These are the tables the dashboard queries directly.

---

### `rpt_ads_daily`

**Grain:** date + source + campaign_id + ad_group_id
**Use for:** Time series charts, day-level trend lines, ad group drilldowns

This is ` unified_model` with no aggregation — all columns are passed through. Use this table when the user wants to see daily movement, compare specific campaigns over time, or drill into ad group performance.

All columns from ` unified_model` are present. See that table for the full schema.

**Key use cases:**
- Daily spend trend line by platform
- CTR / CPA trend over time for a specific campaign
- TikTok video funnel by day (watch_rate_25 → 100)
- Facebook frequency warnings (frequency rising = audience fatigue)

---

### `rpt_ads_campaign_summary`

**Grain:** source + campaign_id + campaign_name
**Use for:** Campaign ranking tables, cross-platform comparisons, top/bottom performers

Aggregated across the full date range in the data. No date dimension — this is a lifetime summary per campaign.

| Column | Type | Description |
|--------|------|-------------|
| `source` | string | Platform |
| `campaign_id` | string | Campaign ID |
| `campaign_name` | string | Campaign name |
| `first_seen_date` | date | Earliest date the campaign appears in data |
| `last_seen_date` | date | Most recent date in data |
| `active_days` | int | Number of distinct days with data |
| `total_impressions` | int | Sum of impressions |
| `total_clicks` | int | Sum of clicks |
| `total_cost` | float | Sum of spend |
| `total_conversions` | int | Sum of conversions |
| `total_conversion_value` | float | Sum of revenue value (Google only) |
| `total_reach` | int | Sum of reach (Facebook only) |
| `total_video_views` | int | Sum of video views (Facebook, TikTok) |
| `total_video_completions` | int | Sum of 100% video completions (TikTok only) |
| `total_engagement_actions` | int | Sum of likes + shares + comments (TikTok only) |
| `ctr` | float | total_clicks / total_impressions |
| `cpc` | float | total_cost / total_clicks |
| `cpm` | float | total_cost / total_impressions × 1000 |
| `cpa` | float | total_cost / total_conversions |
| `conversion_rate` | float | total_conversions / total_clicks |
| `roas` | float | total_conversion_value / total_cost (Google only) |
| `video_completion_rate` | float | total_video_completions / total_video_views (TikTok only) |
| `avg_daily_spend` | float | total_cost / active_days |

**Key use cases:**
- Ranked table: top 10 campaigns by ROAS or CPA
- Cross-platform comparison: same budget, different returns
- Bar chart: total spend vs total conversions by campaign
- Scatter plot: CPA vs conversion volume (efficiency vs scale)

---

### `rpt_ads_platform_summary`

**Grain:** date + source
**Use for:** Platform-level daily blended view, WoW/MoM KPI cards, trend comparison across platforms

One row per platform per day. Pre-computed rolling averages and period-over-period deltas are included — these are ready to feed directly into dashboard KPI cards without additional calculation.

| Column | Type | Description |
|--------|------|-------------|
| `date` | date | Report date |
| `source` | string | Platform |
| `impressions` | int | Daily impressions |
| `clicks` | int | Daily clicks |
| `cost` | float | Daily spend |
| `conversions` | int | Daily conversions |
| `conversion_value` | float | Daily revenue value (Google only) |
| `reach` | int | Daily reach (Facebook only) |
| `video_views` | int | Daily video views (Facebook, TikTok) |
| `video_completions` | int | Daily 100% completions (TikTok only) |
| `engagement_actions` | int | Daily likes + shares + comments (TikTok only) |
| `ctr` | float | clicks / impressions |
| `cpc` | float | cost / clicks |
| `cpm` | float | cost / impressions × 1000 |
| `cpa` | float | cost / conversions |
| `conversion_rate` | float | conversions / clicks |
| `roas` | float | conversion_value / cost (Google only) |
| `video_completion_rate` | float | video_completions / video_views (TikTok only) |
| `social_engagement_rate` | float | engagement_actions / impressions (TikTok only) |
| `cost_7d_avg` | float | 7-day rolling average of cost (per platform) |
| `cpa_7d_avg` | float | 7-day rolling average of CPA (per platform) |
| `ctr_7d_avg` | float | 7-day rolling average of CTR (per platform) |
| `roas_7d_avg` | float | 7-day rolling average of ROAS (per platform) |
| `cost_wow_prior` | float | cost from 7 days ago (same platform) |
| `conversions_wow_prior` | int | conversions from 7 days ago (same platform) |
| `cpa_wow_prior` | float | CPA from 7 days ago (same platform) |
| `cost_mom_prior` | float | cost from 30 days ago (same platform) |
| `cpa_mom_prior` | float | CPA from 30 days ago (same platform) |
| `cost_wow_pct_change` | float | (cost - cost_wow_prior) / cost_wow_prior |
| `conversions_wow_pct_change` | float | (conversions - conversions_wow_prior) / conversions_wow_prior |
| `cpa_wow_pct_change` | float | (cpa - cpa_wow_prior) / cpa_wow_prior |
| `cost_mom_pct_change` | float | (cost - cost_mom_prior) / cost_mom_prior |
| `cpa_mom_pct_change` | float | (cpa - cpa_mom_prior) / cpa_mom_prior |

**Key use cases:**
- KPI cards: current CPA vs WoW (use `cpa` + `cpa_wow_pct_change`)
- Spend pacing line chart with 7d rolling average overlay
- Multi-line chart: CPA trend per platform over time
- Platform comparison bar: total cost / conversions by source for a date range

---

## Metric Reference

### Universal metrics (all platforms)

| Metric | Formula | Interpretation |
|--------|---------|----------------|
| CTR | clicks / impressions | Higher = better ad relevance |
| CPC | cost / clicks | Lower = more efficient traffic acquisition |
| CPM | cost / impressions × 1000 | Lower = cheaper reach |
| CPA | cost / conversions | Lower = more efficient conversion |
| Conversion rate | conversions / clicks | Higher = better landing page + audience fit |

### Platform-specific metrics

| Metric | Platform | Formula | Interpretation |
|--------|----------|---------|----------------|
| ROAS | Google | conversion_value / cost | Higher = more revenue per dollar spent |
| Quality score | Google | Native (1–10) | Higher = lower future CPCs |
| Search impression share | Google | Native (0–1) | Lower = budget or quality score limiting reach |
| Frequency | Facebook | Native | Rising frequency = audience fatigue risk |
| Reach | Facebook | Native | Unique users — compare to impressions to gauge overlap |
| Video completion rate | TikTok | watch_100 / video_views | Higher = content holds attention |
| Social engagement rate | TikTok | (likes+shares+comments) / impressions | Higher = content resonates |

### Watch funnel (TikTok)

The four `watch_rate_*` columns form a completion funnel:
- `watch_rate_25` → `watch_rate_50` → `watch_rate_75` → `watch_rate_100`
- A steep drop between 25% and 50% indicates the hook isn't holding
- High `watch_rate_100` with low `conversion_rate` = strong content, weak CTA

---

## Dashboard Query Patterns

**KPI card — blended spend today with WoW change:**
```sql
select
    sum(cost) as total_cost,
    avg(cost_wow_pct_change) as wow_pct
from rpt_ads_platform_summary
where date = current_date - 1
```

**Platform comparison — last 30 days:**
```sql
select
    source,
    sum(cost) as spend,
    sum(conversions) as conversions,
    safe_divide(sum(cost), sum(conversions)) as cpa
from rpt_ads_platform_summary
where date >= current_date - 30
group by 1
order by cpa asc
```

**Top campaigns by CPA — all time:**
```sql
select
    source,
    campaign_name,
    total_cost,
    total_conversions,
    cpa
from rpt_ads_campaign_summary
where total_conversions > 0
order by cpa asc
limit 10
```

**TikTok video funnel — last 14 days:**
```sql
select
    campaign_name,
    avg(watch_rate_25) as p25,
    avg(watch_rate_50) as p50,
    avg(watch_rate_75) as p75,
    avg(watch_rate_100) as p100
from rpt_ads_daily
where source = 'tiktok'
  and date >= current_date - 14
group by 1
order by p100 desc
```

**Facebook frequency alert — campaigns above 3.0:**
```sql
select
    campaign_name,
    avg(frequency) as avg_frequency,
    sum(cost) as spend
from rpt_ads_daily
where source = 'facebook'
  and date >= current_date - 7
group by 1
having avg(frequency) > 3.0
order by avg_frequency desc
```

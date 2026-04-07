# Looker Studio Dashboard Definitions

[Dashboard](https://lookerstudio.google.com/u/1/reporting/61577802-bc4f-4903-b8fd-62ae6bd937ba/page/p_n33chz9i2d)

## Paid Ads Performance Dashboard — Google · Facebook · TikTok

> All formulas are Looker Studio calculated fields referencing `rpt_ads_daily` unless the Source Table column states otherwise.
> Fields marked **custom** must be created manually: Resource → Manage data sources → Add a field.
> **Platform** column: `ALL` = all three sources · `G` = Google only · `FB` = Facebook only · `TT` = TikTok only.
> **Good direction**: ↑ = higher is better · ↓ = lower is better · `~` = context-dependent.

---

## 1. Core Performance KPIs

| KPI | Definition | Looker Studio Formula | Source Table | Format | Platform | Good Direction | Notes |
|---|---|---|---|---|---|---|---|
| Total Spend | Total ad spend across all platforms in the selected period | `SUM(cost)` | `rpt_ads_daily` or `rpt_ads_platform_summary` | Currency, 0 dp | ALL | ~ | Never use `AVG(cost)` — cost is a daily per-row value, not a rate |
| Total Conversions | Total completed goal actions (purchase, lead, sign-up) across all platforms | `SUM(conversions)` | `rpt_ads_daily` or `rpt_ads_platform_summary` | Number | ALL | ↑ | Not deduplicated cross-platform — a user converting on both Google and Facebook is counted twice |
| Avg. CPA | Average cost to acquire one conversion | `SUM(cost) / SUM(conversions)` | `rpt_ads_daily` or `rpt_ads_platform_summary` | Currency, 2 dp | ALL | ↓ | ⚠ Never use `AVG(cpa)` — row-level averaging over-weights low-volume days and produces an incorrect blended rate |
| ROAS | Revenue generated per dollar of ad spend — Google only in this schema | `SUM(conversion_value) / SUM(cost)` | `rpt_ads_daily` or `rpt_ads_platform_summary` | Number + "x", 2 dp | G | ↑ | ⚠ Label as "Google ROAS". Facebook/TikTok have NULL conversion_value. Apply `source = google` filter or use `SUM(IFNULL(conversion_value, 0)) / SUM(cost)` for blended future use |
| Total Impressions | Total times ads were displayed to users | `SUM(impressions)` | `rpt_ads_daily` or `rpt_ads_platform_summary` | Number, abbreviated (40.5M) | ALL | ↑ | — |

---

## 2. WoW (Week-over-Week) Comparison Metrics

> All five use Looker Studio's native **Comparison date range: Previous period** — no custom delta formula required.
> ⚠ Do not use the pre-built `cost_wow_prior` / `cpa_wow_prior` columns as scorecard target metrics. Looker Studio SUMs them across all visible rows rather than isolating the correct 7-day window.

| KPI | Primary Metric Formula | Source Table | Good Direction | Scorecard Setting |
|---|---|---|---|---|
| Spend WoW | `SUM(cost)` | `rpt_ads_platform_summary` | ~ | Comparison date range: Previous period |
| Conversions WoW | `SUM(conversions)` | `rpt_ads_platform_summary` | ↑ | Comparison date range: Previous period |
| CPA WoW | `SUM(cost) / SUM(conversions)` | `rpt_ads_platform_summary` | ↓ | Comparison date range: Previous period + enable **Comparison direction: reversed** so negative delta = green |
| ROAS WoW | `SUM(conversion_value) / SUM(cost)` | `rpt_ads_platform_summary` | ↑ | Comparison date range: Previous period + apply `source = google` filter |
| Impressions WoW | `SUM(impressions)` | `rpt_ads_platform_summary` | ↑ | Comparison date range: Previous period |

---

## 3. Efficiency Metrics

| KPI | Definition | Looker Studio Formula | Source Table | Format | Platform | Good Direction | Notes |
|---|---|---|---|---|---|---|---|
| CTR | % of impressions that resulted in a click | `SUM(clicks) / SUM(impressions)` | `rpt_ads_daily` | Percent, 2 dp | ALL | ↑ | ⚠ Never use `AVG(ctr)` — same row-level averaging problem as CPA. Jan 2024: Google 1.90%, Facebook 1.96%, TikTok 1.61% |
| CPC | Average cost paid per click | `SUM(cost) / SUM(clicks)` | `rpt_ads_daily` | Currency, 2 dp | ALL | ↓ | — |
| CPM | Cost to serve 1,000 impressions | `(SUM(cost) / SUM(impressions)) * 1000` | `rpt_ads_daily` | Currency, 2 dp | ALL | ↓ | — |
| Conversion Rate | % of clicks that resulted in a conversion | `SUM(conversions) / SUM(clicks)` | `rpt_ads_daily` | Percent, 2 dp | ALL | ↑ | — |
| CPA by Platform | CPA per platform — use `source` as breakdown dimension in bar chart | `SUM(cost) / SUM(conversions)` | `rpt_ads_platform_summary` | Currency, 2 dp | ALL | ↓ | Jan 2024: Facebook $7.64 · Google $8.93 · TikTok $11.00 |

---

## 4. Google-Specific Metrics

> Apply chart filter `source Equal to google`. These columns are NULL for Facebook and TikTok rows.

| KPI | Definition | Looker Studio Formula | Source Table | Format | Good Direction | Notes |
|---|---|---|---|---|---|---|
| Quality Score | Google's 1–10 rating of keyword, ad, and landing page relevance. Higher scores reduce CPC and improve ad position | `AVG(quality_score)` | `rpt_ads_daily` | Number, 1 dp | ↑ | Jan 2024: Brand Search 9.0 · Shopping 8.0 · Display 7.0 · Generic Search 6.8 |
| Quality Score Band | Groups QS into colour-coded tiers for conditional formatting | `CASE WHEN AVG(quality_score) >= 8 THEN 'Good (8–10)' WHEN AVG(quality_score) >= 6 THEN 'Average (6–7)' ELSE 'Poor (<6)' END` | `rpt_ads_daily` | Text (dimension) | ↑ | Bind Good → green, Average → amber, Poor → red in chart style panel |
| Search Impression Share | % of eligible auctions where the ad actually appeared. The remainder was lost to budget or low Ad Rank | `AVG(search_impression_share)` | `rpt_ads_daily` | Percent, 1 dp | ↑ | Raw column is decimal (0.91 = 91%) — Looker Studio percent format handles ×100. Jan 2024: Brand 91.4% · Shopping 66.9% · Generic 44.4% · Display 34.6% |
| Search Impression Share Gap | % of eligible impressions being missed | `1 - AVG(search_impression_share)` | `rpt_ads_daily` | Percent, 1 dp | ↓ | Complement of SIS. Jan 2024: Generic Search missing 55.6% of eligible impressions |
| Google ROAS | Revenue per dollar spent — Google campaigns only | `SUM(conversion_value) / SUM(cost)` | `rpt_ads_daily` | Number + "x", 2 dp | ↑ | Scoped via `source = google` filter. Jan 2024: Brand Search 9.8x · Shopping 7.9x · Display 5.1x · Generic Search 2.0x |

---

## 5. Facebook-Specific Metrics

> Apply chart filter `source Equal to facebook`. Reach and Frequency columns are NULL for Google and TikTok rows.

| KPI | Definition | Looker Studio Formula | Source Table | Format | Good Direction | Notes |
|---|---|---|---|---|---|---|
| Reach | Number of unique users who saw the ad at least once | `SUM(reach)` | `rpt_ads_daily` | Number | ↑ | Facebook rows only |
| Frequency | Average number of times a unique user saw the ad (Impressions / Reach) | `AVG(frequency)` | `rpt_ads_daily` | Number, 2 dp | ↓ | ⚠ Use `AVG(frequency)` not `SUM(frequency)/SUM(reach)` — column is pre-computed. Alert threshold: >3.0 = audience fatigue. Jan 2024 range: 1.18–1.34 (healthy) |

---

## 6. TikTok-Specific Metrics

> Apply chart filter `source Equal to tiktok`. All watch_rate_* columns are NULL for Google and Facebook rows.
> Raw watch rate columns store decimals (0.74 = 74%) — Looker Studio percent format handles the ×100 conversion automatically.

| KPI | Definition | Looker Studio Formula | Source Table | Format | Good Direction | Notes |
|---|---|---|---|---|---|---|
| Video Views | Times the video ad was viewed (counted after 2 seconds of play) | `SUM(video_views)` | `rpt_ads_daily` | Number | ↑ | Also populated for Facebook rows |
| Video View Rate | % of impressions that resulted in a video view | `AVG(video_view_rate)` | `rpt_ads_daily` | Percent, 2 dp | ↑ | Also populated for Facebook rows |
| Watch Rate — 25% | % of video views where the viewer watched at least 25% | `AVG(watch_rate_25)` | `rpt_ads_daily` | Percent, 1 dp | ↑ | TikTok only. Jan 2024 avg: 77.3% |
| Watch Rate — 50% | % of video views where the viewer watched at least 50% | `AVG(watch_rate_50)` | `rpt_ads_daily` | Percent, 1 dp | ↑ | TikTok only. Jan 2024 avg: 55.7% |
| Watch Rate — 75% | % of video views where the viewer watched at least 75% | `AVG(watch_rate_75)` | `rpt_ads_daily` | Percent, 1 dp | ↑ | TikTok only. Jan 2024 avg: 38.7% |
| Watch Rate — 100% (Completion) | % of video views where the viewer watched the entire video — primary creative quality signal | `AVG(watch_rate_100)` | `rpt_ads_daily` | Percent, 1 dp | ↑ | TikTok only. Jan 2024: Influencer Collab 30.4% · Conversion Focus 25.3% · Traffic 23.5% · Awareness GenZ 22.2% |
| Completion Band | Groups completion rate into performance tiers for conditional formatting | `CASE WHEN AVG(watch_rate_100) >= 0.28 THEN 'Strong (>28%)' WHEN AVG(watch_rate_100) >= 0.23 THEN 'Average (23–28%)' ELSE 'Weak (<23%)' END` | `rpt_ads_daily` | Text (dimension) | — | Thresholds based on Jan 2024 data range. Adjust as benchmarks evolve |
| Drop-off: Hook (25→50%) | % of viewers who left between the 25% and 50% mark. High = hook not holding attention | `(AVG(watch_rate_25) - AVG(watch_rate_50)) / AVG(watch_rate_25)` | `rpt_ads_daily` | Percent, 1 dp | ↓ | Jan 2024: Awareness GenZ worst at 37.2% vs Influencer Collab 19.9% |
| Drop-off: Mid (50→75%) | % of viewers who left between the 50% and 75% mark. High = mid-video pacing problem | `(AVG(watch_rate_50) - AVG(watch_rate_75)) / AVG(watch_rate_50)` | `rpt_ads_daily` | Percent, 1 dp | ↓ | Jan 2024 range: 24.7%–35.7% |
| Drop-off: Close (75→100%) | % of viewers who left between 75% and the end. High = CTA or ending not landing | `(AVG(watch_rate_75) - AVG(watch_rate_100)) / AVG(watch_rate_75)` | `rpt_ads_daily` | Percent, 1 dp | ↓ | Jan 2024 range: 32.7%–39.3% |

---

## 7. Pre-built WoW & Rolling Average Columns

> Native columns in `rpt_ads_platform_summary` — no custom formula required.
> ⚠ Do not use as scorecard target metrics with "Metric" comparison type. Use **Previous period** comparison instead.

| Column | Definition | Type |
|---|---|---|
| `cost_wow_prior` | Total spend in the equivalent prior 7-day window | Pre-built |
| `conversions_wow_prior` | Total conversions in the equivalent prior 7-day window | Pre-built |
| `cpa_wow_prior` | CPA in the equivalent prior 7-day window | Pre-built |
| `cost_mom_prior` | Total spend in the equivalent prior 30-day window | Pre-built |
| `cpa_mom_prior` | CPA in the equivalent prior 30-day window | Pre-built |
| `cost_wow_pct_change` | (current cost − prior cost) / prior cost | Pre-built |
| `conversions_wow_pct_change` | (current conv − prior conv) / prior conv | Pre-built |
| `cpa_wow_pct_change` | (current CPA − prior CPA) / prior CPA | Pre-built |
| `cost_mom_pct_change` | (current cost − prior cost) / prior cost, 30-day basis | Pre-built |
| `cpa_mom_pct_change` | (current CPA − prior CPA) / prior CPA, 30-day basis | Pre-built |
| `cost_7d_avg` | 7-day rolling average of daily spend | Pre-built |
| `cpa_7d_avg` | 7-day rolling average of daily CPA | Pre-built |
| `ctr_7d_avg` | 7-day rolling average of daily CTR | Pre-built |
| `roas_7d_avg` | 7-day rolling average of daily ROAS (Google only) | Pre-built |

---

## 8. Custom Dimension Fields

| Field Name | Used In | Formula | Notes |
|---|---|---|---|
| `campaign_type` | Google QS & Search Imp. Share widget | `CASE WHEN campaign_name = 'Search_Brand_Terms' THEN 'Brand Search' WHEN campaign_name = 'Search_Generic_Terms' THEN 'Generic Search' WHEN campaign_name = 'Shopping_All_Products' THEN 'Shopping' WHEN campaign_name = 'Display_Remarketing' THEN 'Display / Remarketing' ELSE campaign_name END` | ELSE fallback catches new campaigns without breaking the chart |
| `tiktok_campaign_type` | TikTok Video Watch Depth widget | `CASE WHEN campaign_name = 'Influencer_Collab' THEN 'Influencer Collab' WHEN campaign_name = 'Conversion_Focus' THEN 'Conversion Focus' WHEN campaign_name = 'Traffic_Campaign' THEN 'Traffic' WHEN campaign_name = 'Awareness_GenZ' THEN 'Awareness — Gen Z' ELSE campaign_name END` | ELSE fallback catches new campaigns without breaking the chart |
| `quality_score_band` | Google QS conditional formatting | `CASE WHEN AVG(quality_score) >= 8 THEN 'Good (8–10)' WHEN AVG(quality_score) >= 6 THEN 'Average (6–7)' ELSE 'Poor (<6)' END` | Bind: Good → green, Average → amber, Poor → red |
| `completion_band` | TikTok Watch Depth conditional formatting | `CASE WHEN AVG(watch_rate_100) >= 0.28 THEN 'Strong (>28%)' WHEN AVG(watch_rate_100) >= 0.23 THEN 'Average (23–28%)' ELSE 'Weak (<23%)' END` | Thresholds based on Jan 2024 actuals — adjust monthly |

---

*Source tables: `rpt_ads_daily` · `rpt_ads_platform_summary` · `rpt_ads_campaign_summary` · `unified_model` — Jan 2024 data.*

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

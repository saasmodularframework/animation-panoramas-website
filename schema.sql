
CREATE DATABASE IF NOT EXISTS ecosystem_analytics;

CREATE TABLE IF NOT EXISTS ecosystem_analytics.grafana_mcp_analytics
(
    event_timestamp DateTime,
    metric_reading  Float64,
    mcp_tool_name   LowCardinality(String),
    service_source  LowCardinality(String)
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(event_timestamp)
ORDER BY (service_source, event_timestamp);

CREATE TABLE IF NOT EXISTS ecosystem_analytics.daily_readings
(
    reading_date             Date,
    service_source           LowCardinality(String),
    temperature_2m_mean      Nullable(Float64),
    precipitation_sum        Nullable(Float64),
    soil_moisture_0_to_7cm   Nullable(Float64),
    et0_fao_evapotranspiration Nullable(Float64)
)
ENGINE = ReplacingMergeTree
ORDER BY (service_source, reading_date);

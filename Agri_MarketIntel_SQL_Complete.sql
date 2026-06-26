-- ============================================================
-- AGRI COMMODITY PRICE FORECASTING & MARKET INTELLIGENCE
-- Complete SQL Script — Case Study Edition
-- PostgreSQL 14+ compatible
-- Author: Agri Intel Project
-- Date: June 2026
-- ============================================================

-- ============================================================
-- SECTION 1: SCHEMA CREATION
-- ============================================================

DROP TABLE IF EXISTS forecasts CASCADE;
DROP TABLE IF EXISTS season_arrivals CASCADE;
DROP TABLE IF EXISTS state_wholesale_prices CASCADE;
DROP TABLE IF EXISTS mandi_prices CASCADE;
DROP TABLE IF EXISTS msp_rates CASCADE;
DROP TABLE IF EXISTS markets CASCADE;
DROP TABLE IF EXISTS commodities CASCADE;
DROP TABLE IF EXISTS commodity_groups CASCADE;
DROP TABLE IF EXISTS states CASCADE;

-- Reference tables
CREATE TABLE commodity_groups (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE commodities (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL UNIQUE,
    group_id        INTEGER REFERENCES commodity_groups(id),
    unit            VARCHAR(20) DEFAULT 'Rs./Quintal',
    is_msp_crop     BOOLEAN DEFAULT FALSE
);

CREATE TABLE states (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    region      VARCHAR(50),
    state_code  CHAR(2)
);

CREATE TABLE markets (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(200) NOT NULL,
    state_id    INTEGER REFERENCES states(id),
    district    VARCHAR(100),
    market_type VARCHAR(50) DEFAULT 'APMC'
);

CREATE TABLE msp_rates (
    id              SERIAL PRIMARY KEY,
    marketing_year  CHAR(7) NOT NULL,
    commodity_id    INTEGER REFERENCES commodities(id),
    season          VARCHAR(10) NOT NULL,
    msp_value       NUMERIC(10,2) NOT NULL,
    UNIQUE (marketing_year, commodity_id, season)
);

CREATE TABLE mandi_prices (
    id              BIGSERIAL PRIMARY KEY,
    trade_date      DATE NOT NULL,
    market_id       INTEGER REFERENCES markets(id),
    commodity_id    INTEGER REFERENCES commodities(id),
    variety         VARCHAR(100),
    grade           VARCHAR(50) DEFAULT 'FAQ',
    min_price       NUMERIC(10,2),
    max_price       NUMERIC(10,2),
    modal_price     NUMERIC(10,2) NOT NULL,
    arrivals        NUMERIC(12,3),
    unit_arrivals   VARCHAR(30) DEFAULT 'Metric Tonnes'
);

CREATE TABLE state_wholesale_prices (
    id                  SERIAL PRIMARY KEY,
    price_month         DATE NOT NULL,
    state_id            INTEGER REFERENCES states(id),
    commodity_id        INTEGER REFERENCES commodities(id),
    avg_price           NUMERIC(10,2),
    prev_month_price    NUMERIC(10,2),
    prev_year_price     NUMERIC(10,2),
    mom_change_pct      NUMERIC(6,2),
    yoy_change_pct      NUMERIC(6,2)
);

CREATE TABLE season_arrivals (
    id                      SERIAL PRIMARY KEY,
    marketing_year          CHAR(7) NOT NULL,
    commodity_id            INTEGER REFERENCES commodities(id),
    season                  VARCHAR(10) NOT NULL,
    avg_price_rs_quintal    NUMERIC(10,2),
    total_arrivals_mt       NUMERIC(15,3),
    msp_value               NUMERIC(10,2),
    msp_premium_pct         NUMERIC(6,2),
    UNIQUE (marketing_year, commodity_id, season)
);

CREATE TABLE forecasts (
    id              BIGSERIAL PRIMARY KEY,
    run_date        DATE NOT NULL,
    commodity_id    INTEGER REFERENCES commodities(id),
    model_name      VARCHAR(50),
    forecast_date   DATE NOT NULL,
    predicted_price NUMERIC(10,2),
    lower_ci        NUMERIC(10,2),
    upper_ci        NUMERIC(10,2),
    mape_estimate   NUMERIC(5,2),
    created_at      TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- SECTION 2: INDEXES
-- ============================================================

CREATE INDEX idx_mandi_date        ON mandi_prices (trade_date DESC);
CREATE INDEX idx_mandi_commodity   ON mandi_prices (commodity_id, trade_date DESC);
CREATE INDEX idx_mandi_market      ON mandi_prices (market_id, trade_date DESC);
CREATE INDEX idx_swp_month         ON state_wholesale_prices (price_month DESC, commodity_id);
CREATE INDEX idx_forecast_date     ON forecasts (run_date DESC, commodity_id);
CREATE INDEX idx_season_year       ON season_arrivals (marketing_year, commodity_id);

-- ============================================================
-- SECTION 3: SEED DATA
-- ============================================================

-- Commodity Groups
INSERT INTO commodity_groups (name, description) VALUES
('Cereals',       'Paddy, Wheat, Maize, Jowar, Bajra, Ragi, Barley'),
('Pulses',        'Red Gram, Bengal Gram, Black Gram, Green Gram, Lentil'),
('Oil Seeds',     'Groundnut, Mustard, Soyabean, Sunflower, Sesame, Castor, Copra'),
('Fibre Crops',   'Cotton, Jute'),
('Vegetables',    'Tomato, Onion, Potato, Brinjal, Cabbage, Cauliflower'),
('Fruits',        'Mango, Banana, Coconut, Grapes, Pomegranate'),
('Spices',        'Turmeric, Ginger, Black Pepper, Cardamom'),
('Plantation',    'Arecanut, Coffee, Tea, Rubber'),
('Others',        'Sugarcane and miscellaneous crops');

-- Commodities
INSERT INTO commodities (name, group_id, is_msp_crop) VALUES
('Paddy (Common)',  1, TRUE),  ('Wheat',         1, TRUE),
('Maize',           1, TRUE),  ('Jowar',          1, TRUE),
('Bajra',           1, TRUE),  ('Ragi',           1, FALSE),
('Red Gram',        2, TRUE),  ('Bengal Gram',    2, TRUE),
('Black Gram',      2, TRUE),  ('Green Gram',     2, TRUE),
('Lentil',          2, TRUE),  ('Groundnut',      3, TRUE),
('Mustard',         3, TRUE),  ('Soyabean',       3, TRUE),
('Sunflower',       3, TRUE),  ('Sesame',         3, FALSE),
('Castor Seed',     3, FALSE), ('Copra',          3, TRUE),
('Cotton',          4, TRUE),  ('Jute',           4, TRUE),
('Tomato',          5, FALSE), ('Onion',          5, FALSE),
('Potato',          5, FALSE), ('Brinjal',        5, FALSE),
('Mango',           6, FALSE), ('Banana',         6, FALSE),
('Coconut',         6, FALSE), ('Tender Coconut', 6, FALSE),
('Turmeric',        7, FALSE), ('Ginger (Green)', 7, FALSE),
('Black Pepper',    7, FALSE), ('Arecanut',       8, FALSE),
('Sugarcane',       9, FALSE);

-- States
INSERT INTO states (name, region, state_code) VALUES
('Karnataka',    'South',    'KA'), ('Maharashtra',  'West',     'MH'),
('Keralam',      'South',    'KL'), ('Telangana',    'South',    'TS'),
('Andhra Pradesh','South',   'AP'), ('Tamil Nadu',   'South',    'TN'),
('Madhya Pradesh','Central', 'MP'), ('Rajasthan',    'North',    'RJ'),
('Uttar Pradesh','North',    'UP'), ('Punjab',       'North',    'PB'),
('Haryana',      'North',    'HR'), ('Goa',          'West',     'GA'),
('Meghalaya',    'NE',       'ML'), ('Nagaland',     'NE',       'NL'),
('Gujarat',      'West',     'GJ');

-- Markets (Karnataka APMCs)
INSERT INTO markets (name, state_id, district, market_type) VALUES
('Arasikere APMC',      1,'Hassan',          'APMC'),
('Belur APMC',          1,'Hassan',          'APMC'),
('Hassan APMC',         1,'Hassan',          'APMC'),
('Tumkur APMC',         1,'Tumkur',          'APMC'),
('Sira APMC',           1,'Tumkur',          'APMC'),
('Tiptur APMC',         1,'Tumkur',          'APMC'),
('Dharwad APMC',        1,'Dharwad',         'APMC'),
('Hubli APMC',          1,'Dharwad',         'APMC'),
('Gadag APMC',          1,'Gadag',           'APMC'),
('Bidar APMC',          1,'Bidar',           'APMC'),
('Aurad APMC',          1,'Bidar',           'APMC'),
('Byadagi APMC',        1,'Haveri',          'APMC'),
('Haveri APMC',         1,'Haveri',          'APMC'),
('Chikmagalur APMC',    1,'Chikmagalur',     'APMC'),
('Mysore APMC',         1,'Mysore',          'APMC'),
('Chintamani APMC',     1,'Chikkaballapur',  'APMC'),
('Shimoga APMC',        1,'Shimoga',         'APMC'),
('Bagalkot APMC',       1,'Bagalkot',        'APMC');

-- MSP Rates 2025-26
INSERT INTO msp_rates (marketing_year, commodity_id, season, msp_value)
SELECT '2025-26', id, 'Kharif', val
FROM (VALUES
    ('Paddy (Common)',2369), ('Maize',2400), ('Jowar',3699),
    ('Bajra',2775),  ('Red Gram',8000),  ('Black Gram',7100),
    ('Green Gram',8682), ('Groundnut',7263), ('Sunflower',7280),
    ('Soyabean',5328), ('Sesame',8635),  ('Cotton',7710),
    ('Copra',12100)
) AS t(cname, val)
JOIN commodities c ON c.name = t.cname;

INSERT INTO msp_rates (marketing_year, commodity_id, season, msp_value)
SELECT '2025-26', id, 'Rabi', val
FROM (VALUES
    ('Wheat',2425), ('Bengal Gram',5650), ('Lentil',6800),
    ('Mustard',5950), ('Lentil',6800)
) AS t(cname, val)
JOIN commodities c ON c.name = t.cname
ON CONFLICT DO NOTHING;

-- Mandi Prices (representative sample — 22-Jun-2026)
INSERT INTO mandi_prices
    (trade_date, market_id, commodity_id, variety, min_price, max_price, modal_price, arrivals)
SELECT
    '2026-06-22'::DATE,
    m.id,
    c.id,
    variety,
    min_p, max_p, modal_p, arr
FROM (VALUES
    ('Arasikere APMC','Paddy (Common)','Common',   2200,2700,2481,420.0),
    ('Arasikere APMC','Maize',        'Yellow',    2600,2800,2600, 38.2),
    ('Arasikere APMC','Red Gram',     'Local',     7281,10725,7310,14.4),
    ('Arasikere APMC','Bengal Gram',  'Bold',      7735,7735,7735,  0.6),
    ('Arasikere APMC','Black Gram',   'FAQ',       13100,13100,13100,0.9),
    ('Arasikere APMC','Wheat',        'Lokwan',    2825,3300,2825,  8.2),
    ('Arasikere APMC','Castor Seed',  'FAQ',       5500,5500,5500,  3.2),
    ('Byadagi APMC',  'Groundnut',    'Bold',      4089,8109,7018, 57.4),
    ('Byadagi APMC',  'Maize',        'Yellow',    1900,2289,2245, 25.4),
    ('Byadagi APMC',  'Sunflower',    'Hybrid',    7051,7781,7681, 11.6),
    ('Byadagi APMC',  'Wheat',        'Lokwan',    2430,2430,2430,  4.0),
    ('Chintamani APMC','Tomato',      'Local',      800,2200,1500,342.0),
    ('Chintamani APMC','Onion',       'Red',       1200,3500,2200,215.0),
    ('Chintamani APMC','Potato',      'Jyoti',     1200,2400,1800,184.0),
    ('Chintamani APMC','Brinjal',     'Local',      800,1800,1200, 52.0),
    ('Shimoga APMC',  'Paddy (Common)','BPT',      2350,2650,2481,320.0),
    ('Shimoga APMC',  'Arecanut',     'Rashi',    25000,42000,30714,44.0),
    ('Shimoga APMC',  'Copra',        'Milling',  18000,23000,23000,27.8),
    ('Dharwad APMC',  'Cotton',       'Medium',    7000,8200,7435,105.0),
    ('Dharwad APMC',  'Soyabean',     'Yellow',    4400,5500,4798,156.0),
    ('Gadag APMC',    'Mustard',      'Black',     5800,6800,6114, 88.0),
    ('Gadag APMC',    'Jowar',        'Hybrid',    3500,4500,4082, 45.0),
    ('Bidar APMC',    'Turmeric',     'Nizamabad', 7500,12000,9800,38.0),
    ('Bidar APMC',    'Red Gram',     'Desi',      7281,7415,7310,  0.5),
    ('Mysore APMC',   'Mango',        'Totapuri',  2000,8000,4500, 89.0),
    ('Mysore APMC',   'Banana',       'Robusta',   1200,3000,2100, 65.0),
    ('Mysore APMC',   'Coconut',      'Medium',     900,1400,1150,463.0),
    ('Mysore APMC',   'Ginger (Green)','Fresh',    2000,2500,2200, 18.0),
    ('Bagalkot APMC', 'Soyabean',     'Yellow',    7000,7000,7000, 15.0),
    ('Haveri APMC',   'Cotton',       'Long',      7500,8400,7900, 62.0)
) AS t(mkt, com, var, min_p, max_p, modal_p, arr)
JOIN markets    m ON m.name = t.mkt
JOIN commodities c ON c.name = t.com;

-- State-wise wholesale prices (Arecanut)
INSERT INTO state_wholesale_prices
    (price_month, state_id, commodity_id, avg_price, prev_month_price, prev_year_price, mom_change_pct, yoy_change_pct)
SELECT
    '2025-01-01'::DATE, s.id, c.id,
    curr, prev_m, prev_y,
    ROUND((curr - prev_m) / prev_m * 100, 2),
    ROUND((curr - prev_y) / prev_y * 100, 2)
FROM (VALUES
    ('Maharashtra', 66147, 63637, 47500),
    ('Karnataka',   37820, 37979, 40046),
    ('Keralam',     33645, 33514, 36061),
    ('Goa',         31949, 29758, 32585),
    ('Meghalaya',   12123, 11510, 16278),
    ('Nagaland',     2600,  2282,  2600)
) AS t(state_name, curr, prev_m, prev_y)
JOIN states     s ON s.name   = t.state_name
JOIN commodities c ON c.name  = 'Arecanut';

-- Season arrivals 2025-26
INSERT INTO season_arrivals
    (marketing_year, commodity_id, season, avg_price_rs_quintal, total_arrivals_mt, msp_value, msp_premium_pct)
SELECT
    '2025-26', c.id, season, price, arrivals, msp,
    ROUND((price - msp) / msp * 100, 2)
FROM (VALUES
    ('Paddy (Common)','Kharif',2481,285000,2369),
    ('Wheat',         'Rabi',  2488, 92000,2425),
    ('Maize',         'Kharif',2600, 68000,2400),
    ('Jowar',         'Kharif',4082, 24000,3699),
    ('Bajra',         'Kharif',2331, 18000,2775),
    ('Red Gram',      'Kharif',7360, 42000,8000),
    ('Bengal Gram',   'Rabi',  5681, 38000,5650),
    ('Groundnut',     'Kharif',6376, 55000,7263),
    ('Mustard',       'Rabi',  6114, 48000,5950),
    ('Soyabean',      'Kharif',4798, 72000,5328),
    ('Cotton',        'Kharif',7435, 61000,7710),
    ('Copra',         'Kharif',23000, 8200,12100)
) AS t(cname, season, price, arrivals, msp)
JOIN commodities c ON c.name = t.cname;

-- Forecasts (next 7 days, key crops)
INSERT INTO forecasts
    (run_date, commodity_id, model_name, forecast_date, predicted_price, lower_ci, upper_ci, mape_estimate)
SELECT
    '2026-06-22'::DATE, c.id, 'Ensemble',
    '2026-06-22'::DATE + gen.day,
    base_p + (trend_d * gen.day),
    GREATEST(1, base_p + (trend_d * gen.day) - vol),
    base_p + (trend_d * gen.day) + vol,
    mape
FROM (VALUES
    ('Paddy (Common)',2481,-0.8, 45,6.2),
    ('Wheat',         2488, 0.5, 38,5.8),
    ('Maize',         2600,-1.2, 60,8.4),
    ('Tomato',        1500, 2.1,180,12.4),
    ('Onion',         2200,-0.5,120,11.1),
    ('Mustard',       6114, 0.8, 95,7.3),
    ('Cotton',        7435,-0.3,110,8.9),
    ('Copra',        23000, 1.5,380,9.8)
) AS t(cname, base_p, trend_d, vol, mape)
JOIN commodities c ON c.name = t.cname
CROSS JOIN generate_series(1,7) AS gen(day);

-- ============================================================
-- SECTION 4: MATERIALIZED VIEWS
-- ============================================================

CREATE MATERIALIZED VIEW mv_latest_prices AS
SELECT
    mp.trade_date,
    cg.name         AS commodity_group,
    c.name          AS commodity,
    s.name          AS state,
    m.name          AS market,
    m.district,
    mp.variety,
    mp.grade,
    mp.min_price,
    mp.max_price,
    mp.modal_price,
    mp.arrivals,
    mp.unit_arrivals,
    msp.msp_value,
    mp.modal_price - COALESCE(msp.msp_value, mp.modal_price) AS msp_gap_rs,
    CASE
        WHEN msp.msp_value IS NULL            THEN 'No MSP'
        WHEN mp.modal_price < msp.msp_value   THEN 'Below MSP'
        WHEN mp.modal_price < msp.msp_value * 1.05 THEN 'At Par'
        ELSE 'Above MSP'
    END             AS price_status
FROM mandi_prices mp
JOIN commodities  c  ON mp.commodity_id = c.id
JOIN commodity_groups cg ON c.group_id  = cg.id
JOIN markets      m  ON mp.market_id    = m.id
JOIN states       s  ON m.state_id      = s.id
LEFT JOIN msp_rates msp ON (
    msp.commodity_id   = mp.commodity_id
    AND msp.marketing_year = '2025-26'
)
WHERE mp.trade_date = (SELECT MAX(trade_date) FROM mandi_prices)
WITH DATA;

CREATE UNIQUE INDEX idx_mv_latest ON mv_latest_prices (commodity, market, variety);

CREATE MATERIALIZED VIEW mv_commodity_summary AS
SELECT
    cg.name         AS commodity_group,
    c.name          AS commodity,
    COUNT(DISTINCT mp.market_id)                    AS market_count,
    ROUND(SUM(mp.arrivals)::NUMERIC, 2)             AS total_arrivals,
    ROUND(AVG(mp.modal_price)::NUMERIC, 0)          AS avg_modal_price,
    MIN(mp.min_price)                               AS lowest_price,
    MAX(mp.max_price)                               AS highest_price,
    ROUND(AVG(mp.max_price - mp.min_price)::NUMERIC,0) AS avg_spread,
    msp.msp_value,
    ROUND(
        (AVG(mp.modal_price) - COALESCE(msp.msp_value, AVG(mp.modal_price)))
        / NULLIF(msp.msp_value, 0) * 100, 1
    )               AS msp_premium_pct
FROM mandi_prices mp
JOIN commodities c   ON mp.commodity_id = c.id
JOIN commodity_groups cg ON c.group_id  = cg.id
LEFT JOIN msp_rates msp ON (msp.commodity_id = c.id AND msp.marketing_year = '2025-26')
GROUP BY cg.name, c.name, msp.msp_value
WITH DATA;

CREATE UNIQUE INDEX idx_mv_summary ON mv_commodity_summary (commodity);

CREATE MATERIALIZED VIEW mv_state_performance AS
SELECT
    swp.price_month,
    s.name          AS state,
    s.region,
    c.name          AS commodity,
    swp.avg_price,
    swp.prev_month_price,
    swp.prev_year_price,
    swp.mom_change_pct,
    swp.yoy_change_pct,
    RANK() OVER (
        PARTITION BY swp.price_month, swp.commodity_id
        ORDER BY swp.avg_price DESC
    )               AS price_rank
FROM state_wholesale_prices swp
JOIN states      s ON swp.state_id      = s.id
JOIN commodities c ON swp.commodity_id  = c.id
WITH DATA;

-- ============================================================
-- SECTION 5: ANALYSIS QUERIES
-- ============================================================

-- Q1: Today's market summary by commodity group
SELECT
    commodity_group,
    COUNT(DISTINCT commodity)                   AS commodity_count,
    COUNT(*)                                    AS record_count,
    ROUND(SUM(total_arrivals)::NUMERIC, 1)      AS total_arrivals,
    ROUND(AVG(avg_modal_price)::NUMERIC, 0)     AS avg_modal_price,
    SUM(CASE WHEN msp_premium_pct < 0 THEN 1 ELSE 0 END) AS below_msp_count
FROM mv_commodity_summary
GROUP BY commodity_group
ORDER BY total_arrivals DESC;

-- Q2: MSP Risk Report — crops below MSP (intervention trigger)
SELECT
    c.name                                      AS commodity,
    cg.name                                     AS group_name,
    mr.season,
    mr.msp_value                                AS msp_rs,
    AVG(mp.modal_price)                         AS avg_market_price,
    ROUND(AVG(mp.modal_price) - mr.msp_value, 0) AS gap_rs,
    ROUND(
        (AVG(mp.modal_price) - mr.msp_value) / mr.msp_value * 100, 1
    )                                           AS gap_pct,
    SUM(mp.arrivals)                            AS total_arrivals_mt
FROM mandi_prices mp
JOIN commodities c   ON mp.commodity_id = c.id
JOIN commodity_groups cg ON c.group_id  = cg.id
JOIN msp_rates mr    ON (mr.commodity_id = c.id AND mr.marketing_year = '2025-26')
GROUP BY c.name, cg.name, mr.season, mr.msp_value
HAVING AVG(mp.modal_price) < mr.msp_value
ORDER BY gap_pct ASC;

-- Q3: Top 10 markets by total traded value (modal_price × arrivals)
SELECT
    m.name                                      AS market,
    s.name                                      AS state,
    m.district,
    COUNT(DISTINCT mp.commodity_id)             AS commodity_count,
    ROUND(SUM(mp.arrivals), 1)                  AS total_arrivals_mt,
    ROUND(SUM(mp.modal_price * mp.arrivals), 0) AS est_traded_value_rs,
    ROUND(AVG(mp.modal_price), 0)               AS avg_modal_price
FROM mandi_prices mp
JOIN markets m ON mp.market_id = m.id
JOIN states  s ON m.state_id   = s.id
GROUP BY m.name, s.name, m.district
ORDER BY est_traded_value_rs DESC
LIMIT 10;

-- Q4: Seasonal analysis — price spread across months
SELECT
    c.name                                      AS commodity,
    EXTRACT(MONTH FROM mp.trade_date)::INT      AS month_num,
    TO_CHAR(mp.trade_date, 'Mon')               AS month_name,
    ROUND(AVG(mp.modal_price)::NUMERIC, 0)      AS avg_modal_price,
    ROUND(SUM(mp.arrivals)::NUMERIC, 1)         AS total_arrivals,
    COUNT(*)                                    AS observations
FROM mandi_prices mp
JOIN commodities c ON mp.commodity_id = c.id
WHERE c.name = 'Paddy (Common)'
GROUP BY c.name, month_num, month_name
ORDER BY month_num;

-- Q5: Arrivals vs price correlation by commodity
SELECT
    c.name                                      AS commodity,
    cg.name                                     AS commodity_group,
    COUNT(*)                                    AS record_count,
    ROUND(AVG(mp.arrivals)::NUMERIC, 2)         AS avg_arrivals,
    ROUND(AVG(mp.modal_price)::NUMERIC, 0)      AS avg_price,
    ROUND(CORR(mp.arrivals, mp.modal_price)::NUMERIC, 3) AS arrival_price_corr
FROM mandi_prices mp
JOIN commodities c   ON mp.commodity_id = c.id
JOIN commodity_groups cg ON c.group_id  = cg.id
WHERE mp.arrivals > 0
GROUP BY c.name, cg.name
HAVING COUNT(*) >= 2
ORDER BY ABS(CORR(mp.arrivals, mp.modal_price)) DESC NULLS LAST;

-- Q6: State-wise price comparison with rank
SELECT
    state, region, commodity,
    avg_price                                   AS jan_2025_rs,
    prev_month_price                            AS dec_2024_rs,
    prev_year_price                             AS jan_2024_rs,
    mom_change_pct                              AS mom_pct,
    yoy_change_pct                              AS yoy_pct,
    price_rank,
    CASE
        WHEN yoy_change_pct > 10  THEN 'Strong Growth'
        WHEN yoy_change_pct > 0   THEN 'Moderate Growth'
        WHEN yoy_change_pct > -10 THEN 'Slight Decline'
        ELSE 'Sharp Decline'
    END                                         AS yoy_category
FROM mv_state_performance
WHERE price_month = '2025-01-01'
ORDER BY avg_price DESC;

-- Q7: Price volatility index by commodity (spread/modal)
SELECT
    c.name                                      AS commodity,
    cg.name                                     AS group_name,
    ROUND(AVG(mp.min_price)::NUMERIC, 0)        AS avg_min,
    ROUND(AVG(mp.max_price)::NUMERIC, 0)        AS avg_max,
    ROUND(AVG(mp.modal_price)::NUMERIC, 0)      AS avg_modal,
    ROUND(AVG(mp.max_price - mp.min_price)::NUMERIC, 0)      AS avg_spread,
    ROUND(
        AVG((mp.max_price - mp.min_price) / NULLIF(mp.modal_price,0)) * 100, 1
    )                                           AS volatility_index_pct,
    CASE
        WHEN AVG((mp.max_price - mp.min_price) / NULLIF(mp.modal_price,0)) > 0.25 THEN 'High'
        WHEN AVG((mp.max_price - mp.min_price) / NULLIF(mp.modal_price,0)) > 0.10 THEN 'Medium'
        ELSE 'Low'
    END                                         AS volatility_band
FROM mandi_prices mp
JOIN commodities c   ON mp.commodity_id = c.id
JOIN commodity_groups cg ON c.group_id  = cg.id
GROUP BY c.name, cg.name
ORDER BY volatility_index_pct DESC;

-- Q8: Forecast accuracy check (predicted vs hypothetical actual)
SELECT
    f.forecast_date,
    c.name                                      AS commodity,
    f.model_name,
    f.predicted_price,
    f.lower_ci,
    f.upper_ci,
    f.mape_estimate                             AS expected_mape_pct,
    f.upper_ci - f.lower_ci                     AS ci_width_rs,
    CASE
        WHEN f.predicted_price >= mr.msp_value THEN 'Above MSP'
        ELSE 'Below MSP'
    END                                         AS forecast_msp_status
FROM forecasts f
JOIN commodities c  ON f.commodity_id  = c.id
LEFT JOIN msp_rates mr ON (mr.commodity_id = c.id AND mr.marketing_year = '2025-26')
WHERE f.run_date = '2026-06-22'
ORDER BY f.forecast_date, c.name;

-- Q9: Season-wise MSP premium analysis
SELECT
    c.name                                      AS commodity,
    cg.name                                     AS commodity_group,
    sa.season,
    sa.marketing_year,
    sa.msp_value                                AS msp_rs,
    sa.avg_price_rs_quintal                     AS market_price_rs,
    sa.msp_premium_pct,
    sa.total_arrivals_mt,
    CASE
        WHEN sa.msp_premium_pct < -5  THEN 'CRITICAL — Intervention'
        WHEN sa.msp_premium_pct < 0   THEN 'WATCH — Below MSP'
        WHEN sa.msp_premium_pct < 5   THEN 'MARGINAL — Near MSP'
        WHEN sa.msp_premium_pct < 15  THEN 'HEALTHY — Above MSP'
        ELSE 'STRONG — Well above MSP'
    END                                         AS policy_signal
FROM season_arrivals sa
JOIN commodities c   ON sa.commodity_id = c.id
JOIN commodity_groups cg ON c.group_id  = cg.id
ORDER BY sa.msp_premium_pct ASC;

-- Q10: Complete market intelligence summary (Power BI source)
SELECT
    lp.commodity_group,
    lp.commodity,
    lp.state,
    lp.market,
    lp.district,
    lp.modal_price,
    lp.arrivals,
    lp.msp_value,
    lp.msp_gap_rs,
    lp.price_status,
    cs.avg_spread,
    cs.volatility_pct,
    f.predicted_price   AS forecast_7d_price,
    f.lower_ci          AS forecast_7d_lower,
    f.upper_ci          AS forecast_7d_upper
FROM mv_latest_prices lp
JOIN (
    SELECT
        commodity,
        avg_spread,
        ROUND(avg_spread::NUMERIC / NULLIF(avg_modal_price,0) * 100, 1) AS volatility_pct
    FROM mv_commodity_summary
) cs ON cs.commodity = lp.commodity
LEFT JOIN (
    SELECT DISTINCT ON (c.name)
        c.name AS commodity, f.predicted_price, f.lower_ci, f.upper_ci
    FROM forecasts f
    JOIN commodities c ON f.commodity_id = c.id
    WHERE f.run_date = '2026-06-22'
    ORDER BY c.name, f.forecast_date DESC
) f ON f.commodity = lp.commodity
ORDER BY lp.commodity_group, lp.arrivals DESC;

-- ============================================================
-- SECTION 6: STORED PROCEDURES
-- ============================================================

CREATE OR REPLACE FUNCTION get_msp_risk_crops(p_year VARCHAR DEFAULT '2025-26')
RETURNS TABLE (
    commodity       VARCHAR,
    season          VARCHAR,
    msp_value       NUMERIC,
    market_price    NUMERIC,
    gap_rs          NUMERIC,
    gap_pct         NUMERIC,
    risk_level      TEXT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.name,
        mr.season,
        mr.msp_value,
        ROUND(AVG(mp.modal_price)::NUMERIC, 0),
        ROUND((AVG(mp.modal_price) - mr.msp_value)::NUMERIC, 0),
        ROUND(((AVG(mp.modal_price) - mr.msp_value) / mr.msp_value * 100)::NUMERIC, 1),
        CASE
            WHEN AVG(mp.modal_price) < mr.msp_value * 0.95 THEN 'HIGH'
            WHEN AVG(mp.modal_price) < mr.msp_value        THEN 'MEDIUM'
            ELSE 'LOW'
        END
    FROM mandi_prices mp
    JOIN commodities c   ON mp.commodity_id = c.id
    JOIN msp_rates mr    ON (mr.commodity_id = c.id AND mr.marketing_year = p_year)
    GROUP BY c.name, mr.season, mr.msp_value
    ORDER BY gap_pct ASC;
END;
$$;

CREATE OR REPLACE FUNCTION refresh_all_views()
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_latest_prices;
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_commodity_summary;
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_state_performance;
    RAISE NOTICE 'All materialized views refreshed at %', NOW();
END;
$$;

-- ============================================================
-- SECTION 7: POWER BI OPTIMIZED VIEWS
-- ============================================================

CREATE OR REPLACE VIEW vw_powerbi_mandi_prices AS
SELECT
    mp.trade_date                               AS "Date",
    cg.name                                     AS "Commodity Group",
    c.name                                      AS "Commodity",
    s.name                                      AS "State",
    m.district                                  AS "District",
    m.name                                      AS "Market",
    mp.variety                                  AS "Variety",
    mp.min_price                                AS "Min Price (Rs)",
    mp.max_price                                AS "Max Price (Rs)",
    mp.modal_price                              AS "Modal Price (Rs)",
    mp.arrivals                                 AS "Arrivals (MT)",
    mp.modal_price * mp.arrivals               AS "Est Traded Value (Rs)",
    mr.msp_value                                AS "MSP 2025-26 (Rs)",
    mp.modal_price - COALESCE(mr.msp_value, 0) AS "MSP Gap (Rs)",
    ROUND(
        (mp.modal_price - COALESCE(mr.msp_value, mp.modal_price))
        / NULLIF(mr.msp_value, 0) * 100, 1
    )                                           AS "MSP Premium (%)",
    CASE
        WHEN mr.msp_value IS NULL                   THEN 'No MSP'
        WHEN mp.modal_price < mr.msp_value          THEN 'Below MSP'
        WHEN mp.modal_price < mr.msp_value * 1.05   THEN 'At Par'
        ELSE 'Above MSP'
    END                                         AS "Price Status"
FROM mandi_prices mp
JOIN commodities c   ON mp.commodity_id = c.id
JOIN commodity_groups cg ON c.group_id  = cg.id
JOIN markets m       ON mp.market_id    = m.id
JOIN states  s       ON m.state_id      = s.id
LEFT JOIN msp_rates mr ON (mr.commodity_id = c.id AND mr.marketing_year = '2025-26');

CREATE OR REPLACE VIEW vw_powerbi_forecast AS
SELECT
    f.run_date                                  AS "Run Date",
    f.forecast_date                             AS "Forecast Date",
    f.forecast_date - f.run_date               AS "Days Ahead",
    c.name                                      AS "Commodity",
    cg.name                                     AS "Commodity Group",
    f.model_name                                AS "Model",
    f.predicted_price                           AS "Predicted Price (Rs)",
    f.lower_ci                                  AS "Lower CI (Rs)",
    f.upper_ci                                  AS "Upper CI (Rs)",
    f.upper_ci - f.lower_ci                    AS "CI Width (Rs)",
    f.mape_estimate                             AS "MAPE Estimate (%)",
    mr.msp_value                                AS "MSP (Rs)",
    f.predicted_price - COALESCE(mr.msp_value, 0) AS "Forecast MSP Gap (Rs)",
    CASE
        WHEN mr.msp_value IS NULL                       THEN 'No MSP'
        WHEN f.predicted_price < mr.msp_value           THEN 'Forecast Below MSP'
        ELSE 'Forecast Above MSP'
    END                                         AS "Forecast MSP Status"
FROM forecasts f
JOIN commodities c   ON f.commodity_id  = c.id
JOIN commodity_groups cg ON c.group_id  = cg.id
LEFT JOIN msp_rates mr ON (mr.commodity_id = c.id AND mr.marketing_year = '2025-26');

CREATE OR REPLACE VIEW vw_powerbi_seasonal AS
SELECT
    c.name                                      AS "Commodity",
    cg.name                                     AS "Commodity Group",
    mn.month_num                                AS "Month Number",
    mn.month_name                               AS "Month",
    mn.seasonal_index                           AS "Seasonal Index",
    mn.seasonal_index - 100                     AS "Index vs Base",
    CASE
        WHEN mn.seasonal_index >= 110 THEN 'Lean Season (Premium)'
        WHEN mn.seasonal_index <= 90  THEN 'Harvest Season (Discount)'
        ELSE 'Normal Range'
    END                                         AS "Season Type"
FROM commodities c
JOIN commodity_groups cg ON c.group_id = cg.id
CROSS JOIN (VALUES
    (1,'Jan',78),(2,'Feb',75),(3,'Mar',82),(4,'Apr',90),(5,'May',105),(6,'Jun',118),
    (7,'Jul',115),(8,'Aug',108),(9,'Sep',95),(10,'Oct',85),(11,'Nov',82),(12,'Dec',78)
) AS mn(month_num, month_name, seasonal_index)
WHERE c.name = 'Paddy (Common)'
UNION ALL
SELECT c.name, cg.name, mn.month_num, mn.month_name, mn.seasonal_index,
    mn.seasonal_index - 100,
    CASE WHEN mn.seasonal_index >= 110 THEN 'Lean Season (Premium)'
         WHEN mn.seasonal_index <= 90  THEN 'Harvest Season (Discount)'
         ELSE 'Normal Range' END
FROM commodities c JOIN commodity_groups cg ON c.group_id = cg.id
CROSS JOIN (VALUES
    (1,'Jan',95),(2,'Feb',90),(3,'Mar',85),(4,'Apr',80),(5,'May',82),(6,'Jun',92),
    (7,'Jul',115),(8,'Aug',125),(9,'Sep',118),(10,'Oct',105),(11,'Nov',98),(12,'Dec',92)
) AS mn(month_num, month_name, seasonal_index)
WHERE c.name = 'Tomato';

-- ============================================================
-- SECTION 8: VERIFICATION QUERIES
-- ============================================================

SELECT 'Tables created' AS check_type,
    (SELECT COUNT(*) FROM commodity_groups) AS groups,
    (SELECT COUNT(*) FROM commodities)      AS commodities,
    (SELECT COUNT(*) FROM states)           AS states,
    (SELECT COUNT(*) FROM markets)          AS markets,
    (SELECT COUNT(*) FROM msp_rates)        AS msp_rates,
    (SELECT COUNT(*) FROM mandi_prices)     AS mandi_prices,
    (SELECT COUNT(*) FROM state_wholesale_prices) AS state_prices,
    (SELECT COUNT(*) FROM season_arrivals)  AS season_arrivals,
    (SELECT COUNT(*) FROM forecasts)        AS forecasts;

SELECT 'MSP Risk Summary' AS report,
    COUNT(*) FILTER (WHERE msp_premium_pct < 0)   AS below_msp,
    COUNT(*) FILTER (WHERE msp_premium_pct BETWEEN 0 AND 5) AS at_par,
    COUNT(*) FILTER (WHERE msp_premium_pct > 5)   AS above_msp
FROM season_arrivals;

SELECT 'Top 5 Arrivals' AS report, c.name AS commodity,
    SUM(mp.arrivals) AS total_mt
FROM mandi_prices mp JOIN commodities c ON mp.commodity_id = c.id
GROUP BY c.name ORDER BY total_mt DESC LIMIT 5;

-- ============================================================
-- Supply Chain Analytics Queries
-- Database: supplier_inventory | Dialect: PostgreSQL 12+
-- ============================================================


-- ------------------------------------------------------------
-- 1. SUPPLIER ON-TIME DELIVERY RATE
--    Uses FILTER (PostgreSQL-native) instead of CASE WHEN
-- ------------------------------------------------------------
SELECT
    s.company_name AS supplier,
    COUNT(o.order_id) AS total_orders,
    COUNT(*) FILTER (WHERE o.shipped_date <= o.required_date) AS on_time,
    COUNT(*) FILTER (WHERE o.shipped_date > o.required_date) AS late,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE o.shipped_date <= o.required_date)
        / NULLIF(COUNT(o.order_id), 0), 1
    ) AS on_time_rate_pct
FROM orders o
JOIN contract c ON o.contract_id = c.contract_id
JOIN supplier s ON c.supplier_id = s.supplier_id
WHERE o.shipped_date IS NOT NULL
GROUP BY s.supplier_id, s.company_name
ORDER BY on_time_rate_pct DESC;


-- ------------------------------------------------------------
-- 2. LEAD TIME ANALYSIS (avg, median, min, max)
--    Uses PERCENTILE_CONT for median — not possible in T-SQL
-- ------------------------------------------------------------
SELECT
    s.company_name AS supplier,
    m.material_name AS material,
    COUNT(o.order_id) AS total_orders,
    ROUND(AVG(o.shipped_date - o.order_date), 1) AS avg_lead_time_days,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY (o.shipped_date - o.order_date)) AS median_lead_time_days,
    MIN(o.shipped_date - o.order_date) AS min_lead_time_days,
    MAX(o.shipped_date - o.order_date) AS max_lead_time_days
FROM orders o
JOIN contract c ON o.contract_id = c.contract_id
JOIN supplier s ON c.supplier_id = s.supplier_id
JOIN material m ON c.material_id = m.material_id
WHERE o.shipped_date IS NOT NULL
GROUP BY s.supplier_id, s.company_name, m.material_id, m.material_name
ORDER BY avg_lead_time_days DESC;


-- ------------------------------------------------------------
-- 3. CONTRACT SPEND BY SUPPLIER
--    Adds cumulative spend % using window function
-- ------------------------------------------------------------
WITH supplier_spend AS (
    SELECT
        s.company_name AS supplier,
        COUNT(c.contract_id) AS total_contracts,
        SUM(c.contract_value) AS total_spend,
        ROUND(AVG(c.contract_value), 2) AS avg_contract_value,
        MIN(c.price_per_unit) AS min_price_per_unit,
        MAX(c.price_per_unit) AS max_price_per_unit
    FROM contract c
    JOIN supplier s ON c.supplier_id = s.supplier_id
    GROUP BY s.supplier_id, s.company_name
)
SELECT
    supplier,
    total_contracts,
    total_spend,
    avg_contract_value,
    min_price_per_unit,
    max_price_per_unit,
    ROUND(
        100.0 * total_spend / SUM(total_spend) OVER (), 1
    ) AS pct_of_total_spend,
    ROUND(
        100.0 * SUM(total_spend) OVER (ORDER BY total_spend DESC) / SUM(total_spend) OVER (), 1
    ) AS cumulative_spend_pct
FROM supplier_spend
ORDER BY total_spend DESC;


-- ------------------------------------------------------------
-- 4. INVENTORY STATUS WITH ALERTS
--    Uses named status levels — easy to adjust thresholds
-- ------------------------------------------------------------
WITH thresholds AS (
    SELECT
        ui.inventory_id,
        pu.unit_name                        AS production_unit,
        m.material_name                     AS material,
        m.unit                              AS unit_of_measure,
        ui.quantity                         AS current_stock,
        ui.last_updated,
        CASE
            WHEN ui.quantity < 20  THEN 'CRITICAL'
            WHEN ui.quantity < 50  THEN 'LOW'
            WHEN ui.quantity < 100 THEN 'ADEQUATE'
            ELSE                        'SUFFICIENT'
        END                                 AS stock_status,
        CASE
            WHEN ui.quantity < 20  THEN 1
            WHEN ui.quantity < 50  THEN 2
            WHEN ui.quantity < 100 THEN 3
            ELSE                        4
        END                                 AS priority
    FROM unit_inventory ui
    JOIN production_unit pu ON ui.unit_id     = pu.unit_id
    JOIN material        m  ON ui.material_id = m.material_id
)
SELECT
    production_unit,
    material,
    unit_of_measure,
    current_stock,
    last_updated,
    stock_status
FROM thresholds
ORDER BY priority, current_stock;


-- ------------------------------------------------------------
-- 5. MATERIAL PRICE COMPARISON
--    Uses named WINDOW to avoid repeating the partition clause
-- ------------------------------------------------------------
SELECT
    m.material_name                                         AS material,
    s.company_name                                          AS supplier,
    c.price_per_unit,
    MIN(c.price_per_unit)   OVER w                          AS lowest_price,
    MAX(c.price_per_unit)   OVER w                          AS highest_price,
    ROUND(AVG(c.price_per_unit) OVER w, 2)                 AS avg_market_price,
    ROUND(
        100.0 * (c.price_per_unit - MIN(c.price_per_unit) OVER w)
        / NULLIF(MIN(c.price_per_unit) OVER w, 0), 1
    )                                                       AS pct_above_cheapest
FROM contract c
JOIN material m ON c.material_id = m.material_id
JOIN supplier s ON c.supplier_id = s.supplier_id
WINDOW w AS (PARTITION BY m.material_id)
ORDER BY m.material_name, c.price_per_unit;


-- ------------------------------------------------------------
-- 6. MONTHLY ORDER VOLUME TREND
--    Uses DATE_TRUNC (PostgreSQL-native) for proper time series
-- ------------------------------------------------------------
SELECT
    DATE_TRUNC('month', o.order_date)::date                 AS order_month,
    COUNT(o.order_id)                                        AS total_orders,
    COUNT(*) FILTER (WHERE o.status = 'Completed')          AS completed,
    COUNT(*) FILTER (WHERE o.status = 'Pending')            AS pending,
    COUNT(DISTINCT c.supplier_id)                            AS active_suppliers,
    COUNT(DISTINCT o.unit_id)                               AS active_units
FROM orders o
JOIN contract c ON o.contract_id = c.contract_id
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY order_month;


-- ------------------------------------------------------------
-- 7. PENDING ORDERS RISK REPORT
--    CTE separates filtering logic from display logic
-- ------------------------------------------------------------
WITH overdue AS (
    SELECT
        o.order_id,
        s.company_name                      AS supplier,
        m.material_name                     AS material,
        pu.unit_name                        AS destination_unit,
        o.order_date,
        o.required_date,
        (CURRENT_DATE - o.required_date)    AS days_overdue,
        c.contract_value                    AS value_at_risk
    FROM orders o
    JOIN contract        c  ON o.contract_id = c.contract_id
    JOIN supplier        s  ON c.supplier_id = s.supplier_id
    JOIN material        m  ON c.material_id = m.material_id
    JOIN production_unit pu ON o.unit_id     = pu.unit_id
    WHERE o.status = 'Pending'
      AND o.required_date < CURRENT_DATE
)
SELECT
    *,
    SUM(value_at_risk) OVER ()              AS total_value_at_risk
FROM overdue
ORDER BY days_overdue DESC;

# Supplier Inventory Management System

A full-stack supply chain data system, relational PostgreSQL database deployed on a VPS,
with a mobile app frontend for non-technical users and SQL analytics for operations reporting.

## The Problem

Most supply chain teams run on Excel — until the data grows.

During my time as an Operations Analyst procurement data across multiple
unit production units was tracked in disconnected Excel files. This led to:

- **Duplicate supplier records** across sites
- **No cross-unit inventory visibility**
- **No audit trail** for contract-to-order traceability
- **Slow reporting** — weekly procurement status took hours to compile

The typical solution: more Excel sheets, more formulas, more breakage.

The actual solution: a relational database. This project is that.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  AppSheet (Mobile App)                                  │
│  Non-technical users: browse inventory, log movements,  │
│  manage vendors — no SQL required                       │
└────────────────────────┬────────────────────────────────┘
                         │  live read/write
┌────────────────────────▼────────────────────────────────┐
│  PostgreSQL 16 (DigitalOcean VPS, Docker)               │
│  Single source of truth for all procurement data        │
└────────────────────────┬────────────────────────────────┘
                         │  analytical queries
┌────────────────────────▼────────────────────────────────┐
│  Dashboard                                              │
│  On-time delivery, lead time, spend analysis,           │
│  inventory alerts, price benchmarking                   │
└─────────────────────────────────────────────────────────┘
```

## Schema

```
supplier ──────┐
               ├──── contract ──────────── orders
material ──────┘         │                   │
                         │                   │
production_unit ─────────┴── unit_inventory  │
                                             │
                         inventory_movement ─┘
```

### Tables

| Table | Rows (sample) | Description |
|---|---|---|
| `supplier` | 10 | Supplier master: company name, city, province |
| `material` | 4 | Material catalogue with unit of measure |
| `production_unit` | 3 | Asphalt Mixing Plant (AMP) sites |
| `contract` | 36 | Procurement contracts linking supplier + material + unit |
| `orders` | 842 | Purchase orders tied to contracts (2020–2022) |
| `unit_inventory` | 12 | Current stock level per material per production unit |
| `inventory_movement` | 2,085 | Full RECEIPT / CONSUMPTION movement log |

### Key Design Decisions

**Composite PK on `unit_inventory`**
`(unit_id, material_id)` is the natural identity for a stock record — no surrogate key needed. Prevents duplicate entries and makes joins cleaner.

**`inventory_movement` as event log**
Rather than updating stock directly, every receipt and consumption is recorded as a movement. The `unit_inventory` snapshot is derived via `INSERT INTO ... SELECT` from the movement log. This enables:
- Full audit trail with supplier traceability per delivery
- Running balance calculations with window functions
- Consumption rate and turnover analysis

**`orders` linked to `contract`**
Every order must have an approved contract. No maverick spending — the FK constraint enforces it at the database level.

**`contract_value` as computed column**
`GENERATED ALWAYS AS (quantity * price_per_unit) STORED` — calculated automatically, never out of sync.

## Mobile App (AppSheet)

Built with AppSheet connected directly to the live PostgreSQL database on a DigitalOcean VPS.

**Live demo:** [appsheet.com/start/1f866258-db8e-4364-a737-926d9b22dc2a](https://www.appsheet.com/start/1f866258-db8e-4364-a737-926d9b22dc2a)

| View | Description |
|---|---|
| Home | Current inventory levels per unit/material |
| Inventory Log | Full movement history with supplier traceability |
| Vendors | Supplier directory with location info |

## Analytical Queries

See [`analysis.sql`](./analysis.sql) for 7 supply chain performance queries:

| # | Query | Technique |
|---|---|---|
| 1 | Supplier On-Time Delivery Rate | Conditional aggregation (`FILTER`) |
| 2 | Lead Time Analysis | `PERCENTILE_CONT`, named `WINDOW` |
| 3 | Contract Spend by Supplier | CTE, `ROUND`, group aggregation |
| 4 | Inventory Status with Alerts | `CASE` threshold flags |
| 5 | Material Price Benchmarking | Cross-supplier price comparison |
| 6 | Monthly Order Volume Trend | `DATE_TRUNC`, time-series grouping |
| 7 | Pending Orders Risk Report | Multi-table join, overdue detection |

All queries use **PostgreSQL-native syntax**.

## Sample Data

```
Suppliers  : 10  (Jakarta, Bekasi, Medan, Pekanbaru, Dumai, Yogyakarta, Klaten...)
Materials  : 4   (Bitumen, Gravel, Coarse Aggregate, Diesel Fuel)
AMP Sites  : 3   (Pekanbaru, Dumai, JORR-South)
Contracts  : 36  (2020–2022, active + completed)
Orders     : 842 (purchase orders across 3 years)
Movements  : 2,085 (695 receipts + 1,390 consumptions)
```

## Setup

**Requirements:** PostgreSQL 12+

```bash
# 1. Create database
createdb supplier_inventory

# 2. Load schema
psql supplier_inventory -f CreateTable.sql

# 3. Load sample data (inserts must run in order — movements before unit_inventory)
psql supplier_inventory -f InsertData.sql

# 4. Run analysis queries
psql supplier_inventory -f analysis.sql
```

To regenerate sample data with different parameters:
```bash
python3 generate_data.py  # outputs a fresh InsertData.sql
```

Works with DBeaver, TablePlus, pgAdmin, or any PostgreSQL-compatible client.
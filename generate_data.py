"""
Generate realistic sample data for supplier-inventory-db.
Outputs InsertData.sql with:
  - 10 suppliers
  - 4 materials
  - 3 production units
  - 36 contracts (3 per unit × 4 materials × 3 units)
  - ~600 purchase orders
  - 12 unit_inventory records (net from movements)
  - ~2100 inventory movements (RECEIPT + CONSUMPTION)
"""

import random
from datetime import date, timedelta

random.seed(42)

# ── Reference data ─────────────────────────────────────────────

SUPPLIERS = [
    (1,  'PT Karya Agung Mandiri',   'Jl. Industri No. 12',       'Jakarta',    'DKI Jakarta',          '10110'),
    (2,  'CV Maju Bersama',          'Jl. Raya Bekasi No. 45',    'Bekasi',     'Jawa Barat',           '13000'),
    (3,  'PT Sumber Alam Sumatera',  'Jl. Gatot Subroto No. 8',   'Medan',      'Sumatra Utara',        '20000'),
    (4,  'UD Mataram Jaya',          'Jl. Pejanggik No. 3',       'Mataram',    'Nusa Tenggara Barat',  '83100'),
    (5,  'PT Bumi Aceh Resources',   'Jl. T. Nyak Arief No. 1',   'Aceh',       'NAD',                  '24300'),
    (6,  'PT Riau Konstruksi',       'Jl. Sudirman No. 88',       'Pekanbaru',  'Riau',                 '28200'),
    (7,  'CV Dumai Aspal Utama',     'Jl. Nelayan No. 21',        'Dumai',      'Riau',                 '28800'),
    (8,  'PT Klaten Beton Perkasa',  'Jl. Solo-Yogya KM 7',       'Klaten',     'Jawa Tengah',          '57400'),
    (9,  'UD Yogyakarta Material',   'Jl. Magelang No. 15',       'Yogyakarta', 'DIY',                  '55000'),
    (10, 'PT Cileungsi Agregat',     'Jl. Narogong No. 33',       'Cileungsi',  'Jawa Barat',           '16800'),
]

MATERIALS = [
    (1200, 'Bitumen',          'Bitumen pen 60/70 for asphalt paving',         'Cubic Meters'),
    (1300, 'Gravel',           'Crushed stone 14mm-20mm for base course',       'Tons'),
    (1310, 'Coarse Aggregate', 'Coarse aggregate for asphalt mix (AC-WC)',      'Tons'),
    (1400, 'Diesel Fuel',      'Industrial diesel for mixing plant units',      'Liters'),
]

UNITS = [
    (201, 'AMP Pekanbaru',   'Km 12 Jl. Pekanbaru-Dumai',        'Pekanbaru', 'Riau',        '28200'),
    (202, 'AMP Dumai',       'Km 5 Jl. Dumai Industrial',         'Dumai',     'Riau',        '28800'),
    (203, 'AMP JORR-South',  'Jl. JORR Seksi S, Cilandak',       'Jakarta',   'DKI Jakarta', '12430'),
]

# Supplier assignments per unit per material (realistic — not all suppliers serve all units)
SUPPLIER_MAP = {
    # (unit_id, material_id): [supplier_ids]
    (201, 1200): [1, 2],
    (201, 1300): [7, 10],
    (201, 1310): [7, 9],
    (201, 1400): [3, 4],
    (202, 1200): [1, 8, 15],  # fallback to available
    (202, 1300): [4, 10],
    (202, 1310): [5, 7],
    (202, 1400): [2, 3],
    (203, 1200): [1, 6],
    (203, 1300): [4, 8],
    (203, 1310): [7, 10],
    (203, 1400): [2, 3],
}

# Fix fallback to valid supplier IDs
for k in SUPPLIER_MAP:
    SUPPLIER_MAP[k] = [s for s in SUPPLIER_MAP[k] if s <= 10]

BASE_PRICES = {1200: 75.0, 1300: 115.0, 1310: 97.0, 1400: 9.0}

def rand_date(start, end):
    delta = (end - start).days
    return start + timedelta(days=random.randint(0, delta))

def fmt(d):
    return f"'{d}'" if d else 'NULL'

lines = []

# ── Suppliers ──────────────────────────────────────────────────
lines.append("-- SUPPLIERS")
lines.append("INSERT INTO supplier (supplier_id, company_name, address, city, province, postal_code, country)")
lines.append("VALUES")
rows = []
for s in SUPPLIERS:
    rows.append(f"({s[0]}, '{s[1]}', '{s[2]}', '{s[3]}', '{s[4]}', '{s[5]}', 'IDN')")
lines.append(",\n".join(rows) + ";")
lines.append("")

# ── Materials ──────────────────────────────────────────────────
lines.append("-- MATERIALS")
lines.append("INSERT INTO material (material_id, material_name, description, unit)")
lines.append("VALUES")
rows = []
for m in MATERIALS:
    rows.append(f"({m[0]}, '{m[1]}', '{m[2]}', '{m[3]}')")
lines.append(",\n".join(rows) + ";")
lines.append("")

# ── Production Units ───────────────────────────────────────────
lines.append("-- PRODUCTION UNITS")
lines.append("INSERT INTO production_unit (unit_id, unit_name, address, city, province, postal_code, country)")
lines.append("VALUES")
rows = []
for u in UNITS:
    rows.append(f"({u[0]}, '{u[1]}', '{u[2]}', '{u[3]}', '{u[4]}', '{u[5]}', 'IDN')")
lines.append(",\n".join(rows) + ";")
lines.append("")

# ── Contracts ─────────────────────────────────────────────────
# 2 contracts per (unit, material) pair — one 2020, one 2021
lines.append("-- CONTRACTS")
lines.append("INSERT INTO contract (contract_id, supplier_id, material_id, unit_id, quantity, price_per_unit, start_date, end_date, supply_date, status)")
lines.append("VALUES")

contracts = []  # (contract_id, supplier_id, material_id, unit_id)
contract_id = 1001

for unit_id, _, _, _, _, _ in UNITS:
    for mat_id, _, _, _ in MATERIALS:
        suppliers = SUPPLIER_MAP.get((unit_id, mat_id), [1])
        base_price = BASE_PRICES[mat_id]
        for year in [2020, 2021, 2022]:
            sup_id = random.choice(suppliers)
            qty = round(random.uniform(300, 1200), 2)
            price = round(base_price * random.uniform(0.92, 1.1), 2)
            start = date(year, 1, 1)
            end = date(year, 12, 31)
            supply = start + timedelta(days=random.randint(10, 21))
            status = 'Completed' if year == 2020 else ('Active' if year == 2022 else random.choice(['Active', 'Completed']))
            contracts.append((contract_id, sup_id, mat_id, unit_id, qty, price, start, end, supply, status))
            contract_id += 1

rows = []
for c in contracts:
    cid, sid, mid, uid, qty, price, start, end, supply, status = c
    rows.append(f"({cid},{sid},{mid},{uid},{qty},{price},'{start}','{end}','{supply}','{status}')")
lines.append(",\n".join(rows) + ";")
lines.append("")

# ── Orders ────────────────────────────────────────────────────
# ~17 orders per contract → ~612 total
lines.append("-- ORDERS")
lines.append("INSERT INTO orders (order_id, contract_id, unit_id, order_date, required_date, shipped_date, status)")
lines.append("VALUES")

orders = []  # (order_id, contract_id, unit_id, order_date, shipped_date)
order_id = 5001

for c in contracts:
    cid, sid, mid, uid, qty, price, start, end, supply, status = c
    n_orders = random.randint(18, 28)
    for _ in range(n_orders):
        order_date = rand_date(start + timedelta(days=30), end - timedelta(days=14))
        lead_days = random.randint(10, 21)
        required = order_date + timedelta(days=lead_days)
        late_days = random.randint(-3, 6)
        shipped = required + timedelta(days=late_days)
        if shipped > end + timedelta(days=30):
            shipped = required + timedelta(days=random.randint(0, 3))
        ord_status = 'Completed' if status == 'Completed' else random.choice(['Completed', 'Completed', 'Pending'])
        if ord_status == 'Pending':
            shipped = None
        orders.append((order_id, cid, uid, order_date, required, shipped, ord_status))
        order_id += 1

rows = []
for o in orders:
    oid, cid, uid, odate, rdate, sdate, ostatus = o
    shipped_val = f"'{sdate}'" if sdate else 'NULL'
    rows.append(f"({oid},{cid},{uid},'{odate}','{rdate}',{shipped_val},'{ostatus}')")
lines.append(",\n".join(rows) + ";")
lines.append("")

# ── Inventory Movements ───────────────────────────────────────
# RECEIPT for every completed order + CONSUMPTION entries (~1.5x receipts)
lines.append("-- INVENTORY MOVEMENTS")
lines.append("INSERT INTO inventory_movement (movement_id, unit_id, material_id, supplier_id, order_id, movement_type, quantity, movement_date, notes)")
lines.append("VALUES")

movements = []
movement_id = 9001

# Build lookup: contract_id → (supplier_id, material_id)
contract_lookup = {c[0]: (c[1], c[2]) for c in contracts}

# RECEIPT — one per completed order
for o in orders:
    oid, cid, uid, odate, rdate, sdate, ostatus = o
    if ostatus == 'Completed' and sdate:
        sup_id, mat_id = contract_lookup[cid]
        qty = round(random.uniform(20, 100), 2)
        movements.append((movement_id, uid, mat_id, sup_id, oid, 'RECEIPT', qty, sdate, 'Delivery per order'))
        movement_id += 1

# CONSUMPTION — roughly 1.5x receipts, spread across the period
receipt_count = len(movements)
consumption_target = int(receipt_count * 2.0)

# Build list of (unit_id, material_id) combos
unit_mat_pairs = [(u[0], m[0]) for u in UNITS for m in MATERIALS]

period_start = date(2020, 1, 1)
period_end   = date(2022, 12, 31)

for _ in range(consumption_target):
    uid, mat_id = random.choice(unit_mat_pairs)
    qty = round(random.uniform(10, 80), 2)
    cons_date = rand_date(period_start, period_end)
    movements.append((movement_id, uid, mat_id, None, None, 'CONSUMPTION', qty, cons_date, 'Production use'))
    movement_id += 1

# Sort all movements by date
movements.sort(key=lambda x: x[7])

rows = []
for m in movements:
    mid, uid, mat_id, sup_id, oid, mtype, qty, mdate, notes = m
    sup_val = str(sup_id) if sup_id else 'NULL'
    ord_val  = str(oid)   if oid   else 'NULL'
    rows.append(f"({mid},{uid},{mat_id},{sup_val},{ord_val},'{mtype}',{qty},'{mdate}','{notes}')")
lines.append(",\n".join(rows) + ";")
lines.append("")

# ── Unit Inventory (calculated from movements) ────────────────
lines.append("-- UNIT INVENTORY")
lines.append("-- Net stock calculated directly from inventory_movement log")
lines.append("INSERT INTO unit_inventory (unit_id, material_id, quantity, last_updated)")
lines.append("SELECT")
lines.append("    unit_id,")
lines.append("    material_id,")
lines.append("    ROUND(SUM(")
lines.append("        CASE movement_type")
lines.append("            WHEN 'RECEIPT'     THEN  quantity")
lines.append("            WHEN 'CONSUMPTION' THEN -quantity")
lines.append("            ELSE 0")
lines.append("        END")
lines.append("    )::NUMERIC, 2)              AS quantity,")
lines.append("    MAX(movement_date)           AS last_updated")
lines.append("FROM inventory_movement")
lines.append("GROUP BY unit_id, material_id;")
lines.append("")

# ── Write output ──────────────────────────────────────────────
output = "\n".join(lines)

# Stats header
n_contracts  = len(contracts)
n_orders     = len(orders)
n_receipts   = sum(1 for m in movements if m[5] == 'RECEIPT')
n_consumptions = sum(1 for m in movements if m[5] == 'CONSUMPTION')
n_movements  = len(movements)

header = f"""-- ============================================================
-- Sample Data: Supplier-Inventory Database (PostgreSQL)
-- {n_contracts} contracts | {n_orders} orders | {n_receipts} receipts | {n_consumptions} consumptions | {n_movements} total movements
-- ============================================================

"""

with open("InsertData.sql", "w") as f:
    f.write(header + output)

print(f"✅ InsertData.sql written")
print(f"   Suppliers     : {len(SUPPLIERS)}")
print(f"   Materials     : {len(MATERIALS)}")
print(f"   Units         : {len(UNITS)}")
print(f"   Contracts     : {n_contracts}")
print(f"   Orders        : {n_orders}")
print(f"   Movements     : {n_movements} ({n_receipts} receipts + {n_consumptions} consumptions)")
print(f"   Unit inventory: 12 records (calculated from movements)")

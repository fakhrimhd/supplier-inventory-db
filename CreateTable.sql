-- ============================================================
-- Supplier Inventory Management System
-- PostgreSQL 12+ (uses GENERATED ALWAYS AS for computed columns)
-- ============================================================

-- Supplier master data
CREATE TABLE supplier (
    supplier_id   INT          PRIMARY KEY,
    company_name  VARCHAR(150) NOT NULL,
    address       VARCHAR(255),
    city          VARCHAR(100),
    province      VARCHAR(100),
    postal_code   VARCHAR(20),
    country       VARCHAR(10)  DEFAULT 'IDN'
);

-- Material catalogue with unit of measure
CREATE TABLE material (
    material_id   INT          PRIMARY KEY,
    material_name VARCHAR(150) NOT NULL,
    description   VARCHAR(255),
    unit          VARCHAR(50)
);

-- Asphalt Mixing Plant (AMP) production sites
CREATE TABLE production_unit (
    unit_id     INT          PRIMARY KEY,
    unit_name   VARCHAR(150) NOT NULL,
    address     VARCHAR(255),
    city        VARCHAR(100),
    province    VARCHAR(100),
    postal_code VARCHAR(20),
    country     VARCHAR(10)  DEFAULT 'IDN'
);

-- Procurement contracts: links supplier + material + unit
-- contract_value is auto-computed from quantity × price_per_unit
CREATE TABLE contract (
    contract_id    INT             PRIMARY KEY,
    supplier_id    INT             NOT NULL,
    material_id    INT             NOT NULL,
    unit_id        INT             NOT NULL,
    quantity       DECIMAL(18, 2)  NOT NULL,
    price_per_unit DECIMAL(18, 2)  NOT NULL,
    contract_value DECIMAL(18, 2)  GENERATED ALWAYS AS (quantity * price_per_unit) STORED,
    start_date     DATE,
    end_date       DATE,
    supply_date    DATE,
    status         VARCHAR(50)     DEFAULT 'Active',
    FOREIGN KEY (supplier_id) REFERENCES supplier(supplier_id),
    FOREIGN KEY (material_id) REFERENCES material(material_id),
    FOREIGN KEY (unit_id)     REFERENCES production_unit(unit_id)
);

-- Purchase orders — every order must be tied to a contract
CREATE TABLE orders (
    order_id      INT         PRIMARY KEY,
    contract_id   INT         NOT NULL,
    unit_id       INT         NOT NULL,
    order_date    DATE,
    required_date DATE,
    shipped_date  DATE,
    status        VARCHAR(50) DEFAULT 'Pending',
    FOREIGN KEY (contract_id) REFERENCES contract(contract_id),
    FOREIGN KEY (unit_id)     REFERENCES production_unit(unit_id)
);

-- Current stock snapshot per material per production unit
-- Composite PK: a unit can only hold one record per material
CREATE TABLE unit_inventory (
    unit_id      INT            NOT NULL,
    material_id  INT            NOT NULL,
    quantity     DECIMAL(18, 2) NOT NULL DEFAULT 0,
    last_updated DATE,
    PRIMARY KEY (unit_id, material_id),
    FOREIGN KEY (unit_id)     REFERENCES production_unit(unit_id),
    FOREIGN KEY (material_id) REFERENCES material(material_id)
);

-- Full movement log: every receipt and consumption is recorded
-- Enables audit trail, supplier-source tracing, and running balance queries
CREATE TABLE inventory_movement (
    movement_id   INT            PRIMARY KEY,
    unit_id       INT            NOT NULL,
    material_id   INT            NOT NULL,
    supplier_id   INT,
    order_id      INT,
    movement_type VARCHAR(20)    NOT NULL CHECK (movement_type IN ('RECEIPT', 'CONSUMPTION')),
    quantity      DECIMAL(18, 2) NOT NULL CHECK (quantity > 0),
    movement_date DATE           NOT NULL,
    notes         VARCHAR(255),
    FOREIGN KEY (unit_id)     REFERENCES production_unit(unit_id),
    FOREIGN KEY (material_id) REFERENCES material(material_id),
    FOREIGN KEY (supplier_id) REFERENCES supplier(supplier_id),
    FOREIGN KEY (order_id)    REFERENCES orders(order_id)
);

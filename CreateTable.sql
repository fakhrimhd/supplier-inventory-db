-- Creating the Supplier table
CREATE TABLE supplier (
    supplier_id INT IDENTITY(1,1) PRIMARY KEY,
    company_name NVARCHAR(100),
    contact_name NVARCHAR(100),
    contact_title NVARCHAR(50),
    address NVARCHAR(255),
    city NVARCHAR(100),
    province NVARCHAR(100),
    postal_code NVARCHAR(20),
    country NVARCHAR(100),
)

-- Creating the Material table
CREATE TABLE material (
    material_id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100),
    description NVARCHAR(255),
    unit NVARCHAR(50)
)

-- Creating the Production Unit table
CREATE TABLE production_unit (
    unit_id INT IDENTITY(1,1) PRIMARY KEY,
    unit_name NVARCHAR(100),
    address NVARCHAR(255),
    city NVARCHAR(100),
    province NVARCHAR(100),
    postal_code NVARCHAR(20),
    country NVARCHAR(100)
)

-- Creating the Contract table
CREATE TABLE contract (
    contract_id INT IDENTITY(1,1) PRIMARY KEY,
    supplier_id INT,
    material_id INT,
    unit_id INT,
    quantity DECIMAL(18, 2),
    price_per_unit DECIMAL(18, 2),
    contract_value AS (quantity * price_per_unit),
    start_date DATE,
    end_date DATE,
    supply_date DATE,
    status NVARCHAR(50),
    FOREIGN KEY (supplier_id) REFERENCES supplier(supplier_id),
    FOREIGN KEY (material_id) REFERENCES material(material_id),
    FOREIGN KEY (unit_id) REFERENCES production_unit(unit_id)
)

-- Creating the Unit Inventory table
CREATE TABLE unit_inventory (
    inventory_id INT IDENTITY(1,1) PRIMARY KEY,
    unit_id INT,
    material_id INT,
    quantity DECIMAL(18, 2),
    last_updated DATE,
    FOREIGN KEY (unit_id) REFERENCES production_unit(unit_id),
    FOREIGN KEY (material_id) REFERENCES material(material_id)
);

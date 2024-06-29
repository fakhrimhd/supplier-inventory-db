-- Insert data into the Supplier table
INSERT INTO supplier (supplier_id, company_name, address, city, province, postal_code, country)
VALUES 
(001, 'Supplier A', 'Address A', 'Jakarta', 'DKI Jakarta', '10110', 'IDN'),
(002, 'Supplier B', 'Address B', 'Bekasi', 'Jawa Barat', '13000', 'IDN'),
(003, 'Supplier C', 'Address C', 'Medan', 'Sumatra Utara', '20000', 'IDN'),
(004, 'Supplier D', 'Address D', 'Mataram', 'Nusa Tenggara Barat', '83100', 'IDN'),
(005, 'Supplier E', 'Address E', 'Aceh', 'NAD', '24300', 'IDN'),
(006, 'Supplier F', 'Address F', 'Pekanbaru', 'Riau', '28200', 'IDN'),
(007, 'Supplier G', 'Address G', 'Dumai', 'Riau', '28800', 'IDN'),
(008, 'Supplier H', 'Address H', 'Klaten', 'Jawa Tengah', '57400', 'IDN'),
(009, 'Supplier I', 'Address I', 'Yogyakarta', 'DIY', '55000', 'IDN'),
(010, 'Supplier J', 'Address J', 'Cileungsi', 'Jawa Barat', '16800', 'IDN');


-- Insert data into the Material table
INSERT INTO material (material_id, name, description, unit)
VALUES 
(1200, 'Bitumen', 'Bitumen type A', 'Cubic Meters'),
(1300, 'Gravel', 'Gravel type X (14mm-20mm)', 'Tons'),
(1310, 'Coarse Aggregate', 'Aggregate A', 'Tons'),
(1400, 'Solar', 'Industrial solar', 'Liters');

-- Insert data into the Production Unit table
INSERT INTO production_unit (unit_id, unit_name, address, city, province, postal_code, country)
VALUES 
(201, 'Unit A', 'Address unit A', 'Medan', 'Sumatra Utara', '20000', 'IDN'),
(202, 'Unit B', 'Address unit B', 'Bandung', 'Jawa Barat', '40100', 'IDN');

-- Insert data into the Contract table
INSERT INTO contract (contract_id, supplier_id, material_id, unit_id, quantity, price_per_unit, start_date, end_date, supply_date, status)
VALUES 
(1010120, 001, 1200, 201, 100, 75.00, '2020-01-01', '2020-12-31', '2020-01-15', 'Active'),
(2010120, 002, 1300, 202, 50, 120.00, '2020-02-01', '2020-11-30', '2020-02-20', 'Active');

-- Insert data into the Orders table
INSERT INTO orders (order_id, contract_id, unit_id, order_date, required_date, shipped_date, status)
VALUES 
(1, 1010120, 201, '2020-01-10', '2022-01-20', '2022-01-15', 'Completed'),
(2, 1010120, 201, '2020-02-15', '2022-03-01', '2022-02-25', 'Pending');

-- Insert data into the Unit Inventory table
INSERT INTO unit_inventory (unit_id, material_id, quantity, last_updated)
VALUES 
(201, 1310, 130, '2020-06-01'),
(202, 1400, 1000, '2020-06-01');

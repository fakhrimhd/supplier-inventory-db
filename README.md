# Relational Supplier-Inventory Database

## Description
This personal project introduces a relational database designed to manage suppliers, materials, contracts, and inventory across multiple production units for a construction manufacturing company. The primary goal of this database is to replace inefficient spreadsheet-based data management systems with a robust, scalable, SQL-based solution. 

## Table Structure

- `supplier`: Contains information about material suppliers.
- `material`: Details about materials supplied.
- `production_unit`: Information on various production units within the company.
- `contract`: Contract details, including associated supplier, material, and production unit.
- `unit_inventory`: Inventory details for each material at each production unit.

## Database Setup
Clone the repository or download the SQL script files.
Open your SQL Server management environment (e.g., SSMS).
Execute the SQL scripts to create the database and tables.

## Usage
To interact with the database, use SQL queries to insert, update, delete, or select data. Below are examples of how to insert data into each table:

```sql
-- Insert data into the Supplier table
-- Enable IDENTITY_INSERT for the supplier table
SET IDENTITY_INSERT supplier ON;

INSERT INTO supplier (supplier_id, company_name, address, city, province, postal_code, country)
VALUES 
(001, 'Supplier A', 'Address A', 'Jakarta', 'DKI Jakarta', '10110', 'IDN'),
(002, 'Supplier B', 'Address B', 'Bekasi', 'Jawa Barat', '13000', 'IDN');

-- Disable IDENTITY_INSERT after the insert operation
SET IDENTITY_INSERT supplier OFF;
```
Repeat similar insert commands for other tables as needed, following the table structures defined above.

## License
This project is licensed under the MIT License - see the [LICENSE.md](URL) file for details.

## Contact
For any queries regarding this project, please contact:

Email: fakhrimhd@gmail.com
Project Link: [link](https://fakhrimhd.webflow.io/work/project-1)

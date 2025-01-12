CREATE DATABASE IF NOT EXISTS PIGEON_NORTHWIND;
USE DATABASE PIGEON_NORTHWIND;

CREATE SCHEMA IF NOT EXISTS PIGEON_NORTHWIND_SCHEMA;
USE SCHEMA PIGEON_NORTHWIND_SCHEMA;

CREATE TABLE IF NOT EXISTS categories_staging (
  CategoryID INT,
  CategoryName VARCHAR(25),
  Description VARCHAR(255),
  PRIMARY KEY (CategoryID)
);

CREATE TABLE IF NOT EXISTS customers_staging (
  CustomerID INT,
  CustomerName VARCHAR(50),
  ContactName VARCHAR(50),
  Address VARCHAR(50),
  City VARCHAR(20),
  PostalCode VARCHAR(10),
  Country VARCHAR(15),
  PRIMARY KEY (CustomerID)
);

CREATE TABLE IF NOT EXISTS employees_staging (
  EmployeeID INT,
  LastName VARCHAR(15),
  FirstName VARCHAR(15),
  BirthDate TIMESTAMP,
  Photo VARCHAR(25),
  Notes VARCHAR(1024),
  PRIMARY KEY (EmployeeID)
);

CREATE TABLE IF NOT EXISTS shippers_staging (
  ShipperID INT,
  ShipperName VARCHAR(25),
  Phone VARCHAR(15),
  PRIMARY KEY (ShipperID)
);

CREATE TABLE IF NOT EXISTS suppliers_staging (
  SupplierID INT,
  SupplierName VARCHAR(50),
  ContactName VARCHAR(50),
  Address VARCHAR(50),
  City VARCHAR(20),
  PostalCode VARCHAR(10),
  Country VARCHAR(15),
  Phone VARCHAR(15),
  PRIMARY KEY (SupplierID)
);

CREATE TABLE IF NOT EXISTS products_staging (
  ProductID INT,
  ProductName VARCHAR(50),
  SupplierID INT,
  CategoryID INT,
  Unit VARCHAR(25),
  Price DECIMAL(10,2),
  PRIMARY KEY (ProductID),
  CONSTRAINT fk_products_suppliers
    FOREIGN KEY (SupplierID) REFERENCES suppliers_staging (SupplierID) ON DELETE CASCADE,
  CONSTRAINT fk_products_categories
    FOREIGN KEY (CategoryID) REFERENCES categories_staging (CategoryID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS orders_staging (
  OrderID INT,
  CustomerID INT,
  EmployeeID INT,
  OrderDate TIMESTAMP,
  ShipperID INT,
  PRIMARY KEY (OrderID),
  CONSTRAINT fk_orders_customers
    FOREIGN KEY (CustomerID) REFERENCES customers_staging (CustomerID),
  CONSTRAINT fk_orders_employees
    FOREIGN KEY (EmployeeID) REFERENCES employees_staging (EmployeeID),
  CONSTRAINT fk_orders_shippers
    FOREIGN KEY (ShipperID) REFERENCES shippers_staging (ShipperID)
);

CREATE TABLE IF NOT EXISTS orderdetails_staging (
  OrderDetailID INT,
  OrderID INT,
  ProductID INT,
  Quantity INT,
  PRIMARY KEY (OrderDetailID),
  CONSTRAINT fk_orderdetails_orders
    FOREIGN KEY (OrderID) REFERENCES orders_staging (OrderID),
  CONSTRAINT fk_orderdetails_products
    FOREIGN KEY (ProductID) REFERENCES products_staging (ProductID)
);

COPY INTO categories_staging
FROM @PIGEON_NORTHWIND_SCHEMA/categories.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO suppliers_staging
FROM @PIGEON_NORTHWIND_SCHEMA/suppliers.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO customers_staging
FROM @PIGEON_NORTHWIND_SCHEMA/customers.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO employees_staging
FROM @PIGEON_NORTHWIND_SCHEMA/employees.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO shippers_staging
FROM @PIGEON_NORTHWIND_SCHEMA/shippers.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO products_staging
FROM @PIGEON_NORTHWIND_SCHEMA/products.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO orders_staging
FROM @PIGEON_NORTHWIND_SCHEMA/orders.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO orderdetails_staging
FROM @PIGEON_NORTHWIND_SCHEMA/orderdetails.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

CREATE OR REPLACE TABLE dim_customer AS
SELECT 
    CustomerID AS customer_id,
    CustomerName AS customer_name,
    ContactName AS contact_name,
    City AS city,
    Country AS country,
    PostalCode AS postal_code
FROM customers_staging;

CREATE OR REPLACE TABLE dim_suppliers AS
SELECT 
    SupplierID AS supplier_id,
    SupplierName AS supplier_name,
    ContactName AS contact_name,
    City AS city,
    Country AS country,
    Phone AS phone
FROM suppliers_staging;

CREATE OR REPLACE TABLE dim_employees AS
SELECT 
    EmployeeID AS employee_id,
    CONCAT(FirstName, ' ', LastName) AS full_name,
    BirthDate AS birth_date,
    Photo AS photo,
    Notes AS notes
FROM employees_staging;

CREATE OR REPLACE TABLE dim_shippers AS
SELECT 
    ShipperID AS shipper_id,
    ShipperName AS shipper_name,
    Phone AS phone
FROM shippers_staging;

CREATE OR REPLACE TABLE dim_categories AS
SELECT 
    CategoryID AS category_id,
    CategoryName AS category_name,
    Description AS description
FROM categories_staging;

CREATE OR REPLACE TABLE dim_products AS
SELECT 
    ProductID AS product_id,
    ProductName AS product_name,
    Unit AS unit,
    Price AS price
FROM products_staging;

CREATE OR REPLACE TABLE dim_date AS
SELECT DISTINCT 
    CAST(OrderDate AS DATE) AS date,
    EXTRACT(DAY FROM OrderDate) AS day,
    EXTRACT(MONTH FROM OrderDate) AS month,
    EXTRACT(YEAR FROM OrderDate) AS year,
    EXTRACT(QUARTER FROM OrderDate) AS quarter
FROM orders_staging;

CREATE OR REPLACE TABLE fact_orders AS
SELECT 
    o.OrderID AS fact_id,
    o.CustomerID AS customer_id,
    o.EmployeeID AS employee_id,
    o.OrderDate AS order_date,
    oi.ProductID AS product_id,
    oi.Quantity AS quantity,
    ps.Price AS unit_price, 
    oi.Quantity * ps.Price AS total_price, 
    s.ShipperID AS shipper_id,
    cat.category_id AS category_id,
    ps.SupplierID AS supplier_id
FROM orders_staging o
LEFT JOIN orderdetails_staging oi ON o.OrderID = oi.OrderID
LEFT JOIN dim_date d ON CAST(o.OrderDate AS DATE) = d.date
LEFT JOIN dim_employees e ON o.EmployeeID = e.employee_id
LEFT JOIN shippers_staging s ON o.ShipperID = s.ShipperID
LEFT JOIN products_staging ps ON oi.ProductID = ps.ProductID
LEFT JOIN dim_categories cat ON ps.CategoryID = cat.category_id;

DROP TABLE IF EXISTS categories_staging;
DROP TABLE IF EXISTS customers_staging;
DROP TABLE IF EXISTS employees_staging;
DROP TABLE IF EXISTS shippers_staging;
DROP TABLE IF EXISTS suppliers_staging;
DROP TABLE IF EXISTS products_staging;
DROP TABLE IF EXISTS orders_staging;
DROP TABLE IF EXISTS orderdetails_staging;












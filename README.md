# ETL proces datasetu NorthWind

Tento repozitár obsahuje implementáciu ETL (Extract, Transform, Load) procesu v Snowflake, ktorý je navrhnutý na analýzu dát z datasetu NorthWind. Tento projekt sa zameriava na spracovanie a transformovanie údajov o obchodných transakciách, zákazníkoch a dodávateľoch do formátu, ktorý umožňuje multidimenzionálnu analýzu a vizualizáciu kľúčových metrik.

---

## 1. Úvod a popis zdrojových dát
Cieľom tohto semestrálneho projektu je analyzovať dáta, ktoré sú súčasťou Northwind datasetu. Databáza Northwind, ktorá je dostupná [tu](https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/northwind-pubs), je vzorová databáza určená na demonštráciu a testovanie databázových technológií, ako sú SQL Server a Microsoft Access. Simuluje obchodný scenár spoločnosti Northwind Traders, ktorá sa špecializuje na obchod s potravinami. Obsahuje podrobné údaje, ktoré sú uvedené v tabuľkách.

### Prehľad tabuliek:
- `categories:` uchováva informácie o kategóriách produktov (napr. nápoje, mäsové výrobky)
- `customers:` obsahuje údaje o zákazníkoch (meno, adresa)
- `employees:` ukladá údaje o zamestnancoch firmy (meno, dátum narodenia, fotky, poznámky)
- `shippers:` informácie o dopravcoch (názov firmy, telefón)
- `suppliers:` uchováva údaje o dodávateľoch (meno firmy, adresa, telefón)
- `products:` obsahuje názvy produktov, ceny, množstvá a odkazy na dodávateľov a kategórie
- `orders:` zaznamenáva informácie o objednávkach vrátane zákazníka, zamestnanca, dátumu a dopravcu
- `orderdetails:` obsahuje podrobnosti k objednávkam – produkty, množstvá a ceny

Zámerom ETL procesu je pripraviť a transformovať tieto dáta, aby boli dostupné pre viacdimenzionálnu analýzu.

---

### 1.1 Dátová architektúra

### ERD diagram
Surové dáta sú uložené v relačnej štruktúre, vizualizovanej pomocou entitno-relačného diagramu (ERD).

<p align="center">
  <img src="https://github.com/wrex1k/ETL---NorthWind/blob/main/northwind_erd.png" alt="schéma ERD" width="600">
</p>
<p align="center"><em>Obrázok 1: Entitno-relačná schéma NorthWind</em></p>


---

## 2. Dimenzionálny model

Navrhnutý bol hviezdicový model (star schema), ktorý umožňuje efektívnu analýzu obchodných dát. Centrálnym bodom tohto modelu je faktová tabuľka `fact_orders`, ktorá je prepojená s nasledujúcimi dimenziami:

  - `dim_categories:` uchováva informácie o kategóriách produktov (napr. nápoje, mäsové výrobky)
  - `dim_customer:` obsahuje údaje o zákazníkoch (meno, adresa, kontaktné informácie)
  - `dim_employees:` ukladá údaje o zamestnancoch (meno, dátum narodenia, fotky, poznámky)
  - `dim_shippers:` obsahuje informácie o prepravcoch (názov firmy, telefón)
  - `dim_suppliers:` uchováva údaje o dodávateľoch (názov firmy, mesto, krajina, telefón)
  - `dim_products:` obsahuje názvy produktov, ceny, množstvá a odkazy na dodávateľov a kategórie
  - `dim_date:` uchováva informácie o dátumoch objednávok (dátum, rok, mesiac, deň)
  - `fact_orders:` zaznamenáva informácie o objednávkach (zákazník, zamestnanec, produkt, cena, množstvo)

<p align="center">
  <img src="https://github.com/wrex1k/ETL---NorthWind/blob/main/northwind_starschema.png" alt="hviezdicová_schéma" width="600">
</p>
<p align="center"><em>Obrázok 2: Dimenzionálny model typu hviezda</em></p>

---

### 2.1 Hlavné metriky a kľúče vo faktovej tabuľke

Vo faktovej tabuľke `fact_orders` sú nasledovné hlavné metriky:

  - `quantity` *(počet objednaných položiek)* - množstvo položiek, ktoré zákazník objednal
  - `unit_price` *(cena za jednotku)* - cena jednotky produktu v čase objednávky
  - `total_price` *(celková cena)* - celková cena objednávky, ktorá je výsledkom `quantity * unit_price`

### Kľúče vo faktovej tabuľke:

**Primary Key (PK):** 
   - `order_id:` jedinečný identifikátor objednávky

**Foreign Keys (FK):**
   - `dim_customer_id:` cudzí kľúč na tabuľku **dim_customer** (odkaz na zákazníka)
   - `dim_supplier_id:` cudzí kľúč na tabuľku **dim_suppliers** (odkaz na dodávateľa)
   - `dim_date_id:` cudzí kľúč na tabuľku **dim_date** (odkaz na dátum objednávky)
   - `dim_employee_id:` cudzí kľúč na tabuľku **dim_employees** (odkaz na zamestnanca, ktorý spracoval objednávku)
   - `dim_category_id` cudzí kľúč na tabuľku **dim_categories** (odkaz na kategóriu produktu)
   - `dim_product_id:` cudzí kľúč na tabuľku **dim_products** (odkaz na produkt, ktorý bol objednaný)
   - `dim_shipper_id:` cudzí kľúč na tabuľku **dim_shippers** (odkaz na prepravcu)

---

### 2.2 Typy SCD (Slowly Changing Dimension) dimenzií

- `SCD Typ 1:` Tento typ dimenzie neuchováva historické údaje. Pri zmene údajov sa existujúce hodnoty jednoducho aktualizujú bez uchovávania starších verzií.
- `SCD Typ 2:` Tento typ dimenzie uchováva historické údaje, pričom každý záznam so zmenou je zachovaný ako nová verzia so samostatným dátumom platnosti, čo umožňuje sledovať historické zmeny.
- `SCD Typ 0:` Tento typ dimenzie uchováva iba aktuálne údaje. Nevykonáva sa žiadne verziovanie alebo uchovávanie historických zmien. Je vhodný pre dáta, ktoré sa považujú za nemenné, ako napríklad kalendárne dni alebo kódy krajín, ktoré sa nemenia v čase.

### Typy dimenzií:
- `dim_categories:` **SCD Typ 1**  
- `dim_customers:` **SCD Typ 2**  
- `dim_employees:` **SCD Typ 2**  
- `dim_shippers:` **SCD Typ 1**  
- `dim_suppliers:` **SCD Typ 1**  
- `dim_products:` **SCD Typ 2**  
- `dim_date:` **SCD Typ 0**

---
## 3. ETL proces v nástroji Snowflake

ETL proces v Snowflake sa skladá z troch hlavných fáz: **Extract** *(Extrahovanie)*, **Transform** *(Transformácia)* a **Load** *(Načítanie)*. Tento proces umožňuje pripraviť pôvodné dáta zo zdrojových tabuliek na analýzu v dimenzionálnom modeli, ktorý bol navrhnutý v predchádzajúcej kapitole.

---
### 3.1 Extract (Extrahovanie dát)
Zdrojové dáta vo formáte `.csv` boli nahraté do Snowflake prostredníctvom interného úložiska typu stage, nazvaného `PIGEON_NORTHWIND_STAGE`. Tento stage slúži ako dočasné úložisko na nahrávanie alebo exportovanie dát medzi externými zdrojmi a Snowflake prostredím. 

Na vytvorenie stage bol použitý nasledujúci príkaz:
```sql
CREATE OR REPLACE STAGE PIGEON_NORTHWIND_STAGE;
```
Do `PIGEON_NORTHWIND_STAGE` boli následne nahrané súbory obsahujúce údaje o zákazníkoch, zamestnancoch, produktoch, objednávkach, dodávateľoch, prepravcoch a kategóriách produktov. Dáta boli importované do staging tabuliek pomocou príkazu `COPY INTO`, ktorý umožňuje načítanie dát z externých súborov do dočasných tabuliek v Snowflake. 

Príklad tabuľky `customer_staging`:
```sql
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
```

Príklad príkazu `COPY INTO`:
```sql
COPY INTO categories_staging
FROM @PIGEON_NORTHWIND_SCHEMA/categories.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
```
---
### 3.2 Transform (Transformácia dát) 
Transformácia dát zahŕňa čistenie, obohacovanie a prípravu dimenzií a faktovej tabuľky. Nasledujúce príkazy ukazujú, ako boli vytvorené jednotlivé dimenzie a faktová tabuľka:

### Dimenzia `dim_customer`
```sql
CREATE OR REPLACE TABLE dim_customer AS
SELECT 
    CustomerID AS customer_id,
    CustomerName AS customer_name,
    ContactName AS contact_name,
    City AS city,
    Country AS country,
    PostalCode AS postal_code
FROM customers_staging;
```

### Dimenzia `dim_suppliers`
```sql
CREATE OR REPLACE TABLE dim_suppliers AS
SELECT 
    SupplierID AS supplier_id,
    SupplierName AS supplier_name,
    ContactName AS contact_name,
    City AS city,
    Country AS country,
    Phone AS phone
FROM suppliers_staging;
```

### Dimenzia `dim_employees`
```sql
CREATE OR REPLACE TABLE dim_employees AS
SELECT 
    EmployeeID AS employee_id,
    CONCAT(FirstName, ' ', LastName) AS full_name,
    BirthDate AS birth_date,
    Photo AS photo,
    Notes AS notes
FROM employees_staging;
```

### Dimenzia `dim_shippers`
```sql
CREATE OR REPLACE TABLE dim_shippers AS
SELECT 
    ShipperID AS shipper_id,
    ShipperName AS shipper_name,
    Phone AS phone
FROM shippers_staging;
```

### Dimenzia `dim_categories`
```sql
CREATE OR REPLACE TABLE dim_categories AS
SELECT 
    CategoryID AS category_id,
    CategoryName AS category_name,
    Description AS description
FROM categories_staging;
```

### Dimenzia `dim_products`
```sql
CREATE OR REPLACE TABLE dim_products AS
SELECT 
    ProductID AS product_id,
    ProductName AS product_name,
    Unit AS unit,
    Price AS price
FROM products_staging;
```

### Dimenzia `dim_date`
```sql
CREATE OR REPLACE TABLE dim_date AS
SELECT DISTINCT 
    CAST(OrderDate AS DATE) AS date,
    EXTRACT(DAY FROM OrderDate) AS day,
    EXTRACT(MONTH FROM OrderDate) AS month,
    EXTRACT(YEAR FROM OrderDate) AS year,
    EXTRACT(QUARTER FROM OrderDate) AS quarter
FROM orders_staging;
```

### Faktová tabuľka `fact_orders`
```sql
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
```

### **3.3 Load (Načítanie dát)**

Po úspešnom vytvorení dimenzií a faktovej tabuľky boli staging tabuľky odstránené na optimalizáciu úložiska pomocou týchto príkazov:

```sql
DROP TABLE IF EXISTS categories_staging;
DROP TABLE IF EXISTS customers_staging;
DROP TABLE IF EXISTS employees_staging;
DROP TABLE IF EXISTS shippers_staging;
DROP TABLE IF EXISTS suppliers_staging;
DROP TABLE IF EXISTS products_staging;
DROP TABLE IF EXISTS orders_staging;
DROP TABLE IF EXISTS orderdetails_staging;
```

ETL proces v Snowflake umožnil spracovanie pôvodných dát z formátu `.csv` do viacdimenzionálneho modelu typu hviezda pre dataset NorthWind. Výsledný model umožňuje analýzu obchodných transakcií, správania zákazníkov a výkonu predaja, pričom poskytuje základ pre vizualizácie a reporty.
  
---
## 4. Vizualizácia dát


    
Autor: Pavol Pohánka





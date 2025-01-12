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

Dashboard obsahuje 5 vizualizácií, ktoré odpovedajú na dôležité otázky týkajúce sa výnosov z produktov, aktivity zákazníkov a sezónnych trendov v predaji. Umožňujú identifikovať najziskovejšie kategórie a produkty, najaktívnejších zákazníkov a geografické oblasti s najväčším počtom zákazníkov. Zároveň poskytujú prehľad o dennom vývoji tržieb, čo pomáha lepšie pochopiť správanie zákazníkov a identifikovať obdobia s najvyššími predajmi.

---

### Graf 1: Príjmy podľa kategórii produktov
*Tento graf zobrazuje príjmy z rôznych kategórií produktov. Najvyšší príjem je z kategórie Beverages (nápoje), Dairy Products (mliečne výrobky) a Confections (cukrovinky). Naopak, Grains/Cereals (obilniny/raňajkové cereálie) a Produce (čerstvé ovocie a zelenina) majú najnižšie príjmy. Tento prehľad umožňuje identifikovať, ktoré produktové kategórie generujú najviac príjmov, čo môže pomôcť pri rozhodovaní o marketingových a zásobovacích stratégiách.*
```sql
SELECT 
    dim_categories.category_name, 
    SUM(fact_orders.total_price) AS total_income
FROM fact_orders
JOIN dim_categories ON fact_orders.category_id = dim_categories.category_id
GROUP BY dim_categories.category_name
ORDER BY total_income DESC;
```
<p align="center">
  <img src="https://github.com/wrex1k/northwind-ETL/blob/main/northwind_visualization/Graf%201%20Pr%C3%ADjmy%20pod%C4%BEa%20kateg%C3%B3ri%C3%AD%20produktov.png" alt="Graf 1 Príjmy podľa kategórii produktov">
</p>
<p align="center"><em>Obrázok 3: Graf 1 Príjmy podľa kategórii produktov</em></p>

---

### Graf 2: Zákazníci podľa počtu objednávok (Top 10)
*V grafe sú zobrazení zákazníci s najvyšším počtom objednávok. Ernst Handel vedie s 35 objednávkami, po ktorom nasleduje Rattlesnake Canyon Grocery a Hungry Owl All-Night Grocers. Tento graf pomáha identifikovať najaktívnejších zákazníkov, na ktorých sa možno zamerať s cieľom zlepšiť zákaznícke vzťahy a lojalitu.*
```sql
SELECT 
    dim_customer.customer_name, 
    COUNT(fact_orders.fact_id) AS total_orders
FROM fact_orders
JOIN dim_customer ON fact_orders.customer_id = dim_customer.customer_id
GROUP BY dim_customer.customer_name
ORDER BY total_orders DESC
LIMIT 10;
```
<p align="center">
  <img src="https://github.com/wrex1k/northwind-ETL/blob/main/northwind_visualization/Graf%202%20Z%C3%A1kazn%C3%ADci%20pod%C4%BEa%20po%C4%8Dtu%20objedn%C3%A1vok%20(Top%2010).png" alt="Graf 2 Zákazníci podľa počtu objednávok (Top 10)">
</p>
<p align="center"><em>Obrázok 4: Graf 2 Zákazníci podľa počtu objednávok (Top 10)</em></p>

---

### Graf 3: Najziskovejšie produkty
*Graf znázorňuje najziskovejšie produkty. Côte de Blaye je najvýnosnejší produkt s príjmom 63,096, čo je značne viac ako ostatné produkty. Ďalej nasledujú Thüringer Rostbratwurst a Raclette Courdavault. Tento prehľad pomáha identifikovať produkty, ktoré majú najväčší finančný prínos, čo môže byť užitočné pri rozhodovaní o skladových zásobách a propagácii.*
```sql
SELECT 
    p.product_name, 
    SUM(f.total_price) AS total_income
FROM 
    fact_orders f
JOIN 
    dim_products p ON f.product_id = p.product_id
GROUP BY 
    p.product_name
ORDER BY 
    total_income DESC;
```
<p align="center">
  <img src="https://github.com/wrex1k/northwind-ETL/blob/main/northwind_visualization/Graf%203%20Najziskovej%C5%A1ie%20produkty.png" alt="Graf 3 Najziskovejšie produkty">
</p>
<p align="center"><em>Obrázok 5: Graf 3 Najziskovejšie produkty</em></p>

---

### Graf 4: Počet zákazníkov podľa geografickej polohy
*V tomto grafe je zobrazený počet zákazníkov podľa ich geografického pôvodu. Brazília a Nemecko vedú s 9 zákazníkmi, po ktorých nasleduje USA a Francúzko. Táto vizualizácia môže pomôcť pochopiť, kde je najväčší počet zákazníkov, čo je užitočné pri plánovaní regionálnych marketingových kampaní a logistiky.*
```sql
SELECT 
    c.country AS customers_country, 
    COUNT(DISTINCT f.customer_id) AS total_customers
FROM 
    fact_orders f
JOIN 
    dim_customer c ON f.customer_id = c.customer_id
GROUP BY 
    c.country
ORDER BY 
    total_customers DESC;
```
<p align="center">
  <img src="https://github.com/wrex1k/northwind-ETL/blob/main/northwind_visualization/Graf%204%20Po%C4%8Det%20z%C3%A1kazn%C3%ADkov%20pod%C4%BEa%20geografickej%20polohy.png" alt="Graf 4 Počet zákazníkov podľa geografickej polohy">
</p>
<p align="center"><em>Obrázok 6: Graf 4 Počet zákazníkov podľa geografickej polohy</em></p>

---

### Graf 5: Celkové tržby podľa jednotlivých dní
*Posledný graf zobrazuje denné tržby, pričom sa zaznamenávajú výkyvy v priebehu času. Niektoré dni vykazujú výrazne vyššie tržby, čo môže naznačovať sezónne trendy alebo špeciálne udalosti. Analýza týchto trendov pomáha pri plánovaní zásob a promo akcií v budúcnosti.*
```sql
SELECT 
    dim_date.date, 
    SUM(fact_orders.total_price) AS daily_income
FROM fact_orders
JOIN dim_date ON fact_orders.order_date = dim_date.date
GROUP BY dim_date.date
ORDER BY dim_date.date;
```
<p align="center">
  <img src="https://github.com/wrex1k/northwind-ETL/blob/main/northwind_visualization/Graf%205%20Celkov%C3%A9%20tr%C5%BEby%20pod%C4%BEa%20jednotliv%C3%BDch%20dn%C3%AD.png" alt="">
</p>
<p align="center"><em>Obrázok 7: Graf 5 Celkové tržby podľa jednotlivých dní</em></p>

---
### Záver 

ETL proces implementovaný v Snowflake pre NorthWind dataset umožňuje efektívne spracovanie a transformáciu obchodných dát do dimenzionálneho modelu typu hviezda. Tento model poskytuje základ pre detailnú analýzu obchodných transakcií, zákazníkov, produktov a ďalších kľúčových metrik. Vizualizácie vytvorené na základe transformovaných dát poskytujú cenné poznatky, ktoré môžu pomôcť pri strategickom rozhodovaní a optimalizácii obchodných procesov. Tento projekt zobrazuje, ako môže správne navrhnutý a implementovaný ETL proces výrazne prispieť k zlepšeniu dátovej analytiky a podnikových rozhodovacích procesov.

--- 
**Autor:** Pavol Pohánka





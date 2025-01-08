# ETL proces datasetu NorthWind

Tento repozitár obsahuje implementáciu ETL (Extract, Transform, Load) procesu v Snowflake, ktorý je navrhnutý na analýzu dát z datasetu NorthWind. Tento projekt sa zameriava na spracovanie a transformovanie údajov o obchodných transakciách, zákazníkoch a dodávateľoch do formátu, ktorý umožňuje multidimenzionálnu analýzu a vizualizáciu kľúčových metrik.

---

## 1. Úvod a popis zdrojových dát
Cieľom tohto semestrálneho projektu je analyzovať dáta, ktoré sú súčasťou Northwind datasetu. Databáza Northwind, ktorá je dostupná [tu](https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/northwind-pubs), je vzorová databáza určená na demonštráciu a testovanie databázových technológií, ako sú SQL Server a Microsoft Access. Simuluje obchodný scenár spoločnosti Northwind Traders, ktorá sa špecializuje na obchod s potravinami. Obsahuje podrobné údaje, ktoré sú uvedené v tabuľkách.

### Prehľad tabuliek:
- `Categories:` uchováva informácie o kategóriách produktov (napr. nápoje, mäsové výrobky)
- `Customers:` obsahuje údaje o zákazníkoch (meno, adresa)
- `Employees:` ukladá údaje o zamestnancoch firmy (meno, dátum narodenia, fotky, poznámky)
- `Shippers:` informácie o dopravcoch (názov firmy, telefón)
- `Suppliers:` uchováva údaje o dodávateľoch (meno firmy, adresa, telefón)
- `Products:` obsahuje názvy produktov, ceny, množstvá a odkazy na dodávateľov a kategórie
- `Orders:` zaznamenáva informácie o objednávkach vrátane zákazníka, zamestnanca, dátumu a dopravcu
- `OrderDetails:` obsahuje podrobnosti k objednávkam – produkty, množstvá a ceny

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

Navrhnutý bol hviezdicový model **(star schema)**, ktorý umožňuje efektívnu analýzu obchodných dát. Centrálnym bodom tohto modelu je faktová tabuľka `fact_orders`, ktorá je prepojená s nasledujúcimi dimenziami:
- `dim_categories:` uchováva informácie o kategóriách produktov (napr. nápoje, mäsové výrobky)
- `dim_customer:` obsahuje údaje o zákazníkoch (meno, adresa, kontaktné informácie)
- `dim_employees:` ukladá údaje o zamestnancoch (meno, dátum narodenia, fotky, poznámky)
- `dim_shippers:` informácie o prepravcoch (názov firmy, telefón)
- `dim_suppliers:` uchováva údaje o dodávateľoch (názov firmy, mesto, krajina, telefón)
- `dim_products:` obsahuje názvy produktov, ceny, množstvá a odkazy na dodávateľov a kategórie
- `dim_date:` uchováva informácie o dátumoch objednávok (dátum, rok, mesiac, deň)
- `fact_orders:` zaznamenáva informácie o objednávkach (zákazník, zamestnanec, produkt, cena, množstvo)

<p align="center">
  <img src="https://github.com/wrex1k/ETL---NorthWind/blob/main/northwind_starschema.png" alt="hviezdicová_schéma" width="600">
</p>
<p align="center"><em>Obrázok 2: Dimenzionálny model typu hviezda</em></p>


Týmto spôsobom sa dimenzionálny model stáva flexibilným nástrojom na analýzu a poskytuje potrebné informácie pre rozhodovanie na základe historických aj aktuálnych dát.

---

### 2.1 Hlavné metriky a kľúče vo faktovej tabuľke

Vo faktovej tabuľke `fact_orders` sú nasledovné hlavné metriky:

- `quantity` **(Počet objednaných položiek)** *- množstvo položiek, ktoré zákazník objednal*
- `unit_price` **(Cena za jednotku)** *- cena jednej jednotky produktu v čase objednávky*
- `total_price` **(Celková cena)** *- celková cena objednávky, ktorá je výsledkom `quantity * unit_price`*

---

### 2.2 Typy SCD (Slowly Changing Dimension) dimenzií

- `SCD Type 1`: Tento typ dimenzie neuchováva historické údaje. Pri zmene údajov sa existujúce hodnoty jednoducho aktualizujú bez uchovávania starších verzií.
- `SCD Type 2`: Tento typ dimenzie uchováva historické údaje, pričom každý záznam so zmenou je zachovaný ako nová verzia so samostatným dátumom platnosti, čo umožňuje sledovať historické zmeny.

### Typy dimenzií:
- `dim_categories:` **SCD Type 1** 
- `dim_customers:` **SCD Type 2**
- `dim_employees:` **SCD Type 2** 
- `dim_shippers:` **SCD Type 1** 
- `dim_suppliers:` **SCD Type 1** 
- `dim_products:` **SCD Type 2** 
- `dim_date:` **SCD Type 1**   
---
## 3. ETL proces v nástroji Snowflake

  
---
## 4. Vizualizácia dát


Autor: Pavol Pohánka





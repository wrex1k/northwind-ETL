# ETL proces datasetu NorthWind

Tento repozitár obsahuje implementáciu ETL (Extract, Transform, Load) procesu v Snowflake, ktorý je navrhnutý na analýzu dát z datasetu NorthWind. Tento projekt sa zameriava na spracovanie a transformovanie údajov o obchodných transakciách, zákazníkoch a dodávateľoch do formátu, ktorý umožňuje multidimenzionálnu analýzu a vizualizáciu kľúčových metrik.

---

## 1. Úvod a popis zdrojových dát
Cieľom tohto semestrálneho projektu je analyzovať dáta, ktoré sú súčasťou Northwind datasetu. Databáza Northwind, ktorá je dostupná [tu](https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/northwind-pubs), je vzorová databáza určená na demonštráciu a testovanie databázových technológií, ako sú SQL Server a Microsoft Access. Simuluje obchodný scenár spoločnosti Northwind Traders, ktorá sa špecializuje na obchod s potravinami. Obsahuje podrobné údaje, ktoré sú uvedené v tabuľkách.

### Prehľad tabuliek:
- `Categories:` uchováva informácie o kategóriách produktov (napr. nápoje, mäsové výrobky)
- `Customers:` obsahuje údaje o zákazníkoch, ako je meno, adresa a kontaktné informácie
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
  <img src="https://github.com/user-attachments/assets/b4f6affe-60e6-4f20-b321-93e873664243" alt="ERD diagram" width="600">
</p>
<p align="center"><strong>Obrázok 1: Entitno-relačná schéma NorthWind</p>

---
  
## 2. Návrh dimenzionálneho modelu

  
---
## 3. ETL proces v nástroji Snowflake

  
---
## 4. Vizualizácia dát


Autor: Pavol Pohánka





-- ============================================================
-- Migration: Erweiterung Produkt-Tabelle + neues Sortiment
-- Kraut & Rueben - Warenwirtschaft
-- Encoding: UTF-8 with BOM
-- ============================================================

-- 1. Neue Spalten hinzufuegen (IF NOT EXISTS verhindert Fehler bei erneutem Ausfuehren)
-- -------------------------------------------------------------------------------------

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Produkt' AND COLUMN_NAME = 'Kategorie'
)
    ALTER TABLE Produkt ADD Kategorie NVARCHAR(100) NOT NULL DEFAULT 'Bio-Box';

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Produkt' AND COLUMN_NAME = 'Beschreibung'
)
    ALTER TABLE Produkt ADD Beschreibung NVARCHAR(500) NULL;

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Produkt' AND COLUMN_NAME = 'EinheitMenge'
)
    ALTER TABLE Produkt ADD EinheitMenge DECIMAL(10,3) NOT NULL DEFAULT 1;

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Produkt' AND COLUMN_NAME = 'EinheitTyp'
)
    ALTER TABLE Produkt ADD EinheitTyp NVARCHAR(20) NOT NULL DEFAULT 'kg';

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Produkt' AND COLUMN_NAME = 'IstErnaehrungstrend'
)
    ALTER TABLE Produkt ADD IstErnaehrungstrend BIT NOT NULL DEFAULT 0;

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Produkt' AND COLUMN_NAME = 'IstAktiv'
)
    ALTER TABLE Produkt ADD IstAktiv BIT NOT NULL DEFAULT 1;


-- 2. Bestehende Eintraege normalisieren
-- -------------------------------------------------------------------------------------
UPDATE Produkt
SET Kategorie = 'Bio-Box', IstAktiv = 1
WHERE Kategorie IS NULL OR Kategorie = '';


-- 3. Neue Produkte einfuegen (Duplikatschutz per NOT EXISTS)
-- -------------------------------------------------------------------------------------

-- Bio-Boxen
INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnaehrungstrend, IstAktiv)
SELECT 'Bio-Box Classic', 'Gemischte saisonale Gemüse- und Obstselektion in Bio-Qualitaet.', 'Bio-Box', 24.90, 1, 'Box', 0, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = 'Bio-Box Classic');

INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnaehrungstrend, IstAktiv)
SELECT 'Bio-Box Family', 'Groessere Familienbox fuer 3-4 Personen mit mehr Vielfalt.', 'Bio-Box', 38.90, 1, 'Box', 0, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = 'Bio-Box Family');

INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnaehrungstrend, IstAktiv)
SELECT 'Bio-Box Mini', 'Kompakte Einsteiger-Box fuer 1-2 Personen pro Woche.', 'Bio-Box', 14.90, 1, 'Box', 0, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = 'Bio-Box Mini');

-- Gemüse-Boxen
INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnaehrungstrend, IstAktiv)
SELECT 'Gemuese-Box Standard', 'Saisonales Gemuese aus regionalem Bio-Anbau.', 'Gemüse-Box', 19.90, 1, 'Box', 0, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = 'Gemuese-Box Standard');

INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnaehrungstrend, IstAktiv)
SELECT 'Rohkost-Box', 'Perfekt fuer die Rohkost-Ernaehrung: Karotten, Kohlrabi, Sellerie, Rote Bete.', 'Rohkost-Box', 22.50, 1, 'Box', 1, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = 'Rohkost-Box');

-- Obst-Box
INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnaehrungstrend, IstAktiv)
SELECT 'Obst-Box Classic', 'Saisonale Obstauswahl in zertifizierter Bio-Qualitaet.', 'Obst-Box', 21.90, 1, 'Box', 0, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = 'Obst-Box Classic');

-- Kraeuter-Box
INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnaehrungstrend, IstAktiv)
SELECT 'Kraeuter-Box Premium', 'Frische Kuechenkraeuter: Basilikum, Rosmarin, Thymian, Petersilie, Minze.', 'Kräuter-Box', 12.90, 1, 'Box', 0, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = 'Kraeuter-Box Premium');

-- Ernaehrungstrend-Produkte
INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnaehrungstrend, IstAktiv)
SELECT 'Superfood-Box', 'Brokkoli, Spinat, Gruenkohl, Chia-Samen - reich an Antioxidantien und Naehrstoffen.', 'Superfood-Box', 29.90, 1, 'Box', 1, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = 'Superfood-Box');

INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnaehrungstrend, IstAktiv)
SELECT 'Detox-Box', 'Entgiftend: Ingwer, Kurkuma, Petersilie, Gurke, Zitrone - alles in Bio-Qualitaet.', 'Ernährungstrend', 27.50, 1, 'Box', 1, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = 'Detox-Box');

INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnaehrungstrend, IstAktiv)
SELECT 'Fermentier-Box', 'Alles fuer Fermentation: Weisskohl, Rotkohl, Rueben, Chinakohl - darmfreundlich.', 'Ernährungstrend', 18.90, 1, 'Box', 1, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = 'Fermentier-Box');

-- Saisonale Boxen
INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnaehrungstrend, IstAktiv)
SELECT 'Saisonale Box Sommer', 'Tomaten, Zucchini, Paprika, Gurken - frisch aus der Sommersaison.', 'Saisonale Box', 20.90, 1, 'Box', 0, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = 'Saisonale Box Sommer');

INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnaehrungstrend, IstAktiv)
SELECT 'Saisonale Box Herbst', 'Kuerbis, Sellerie, Pastinaken, Rote Bete - typisch fuer die Herbstsaison.', 'Saisonale Box', 20.90, 1, 'Box', 0, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = 'Saisonale Box Herbst');

-- Einzelprodukte
INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnaehrungstrend, IstAktiv)
SELECT 'Bio-Moehren', 'Frische Bio-Karotten, lose, knackig und suess.', 'Einzelgemüse', 2.49, 1, 'kg', 0, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = 'Bio-Moehren');

INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnaehrungstrend, IstAktiv)
SELECT 'Bio-Ingwer', 'Frischer Bio-Ingwer - Trend-Zutat fuer Tee, Smoothies und Kueche.', 'Ernährungstrend', 1.99, 100, 'g', 1, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = 'Bio-Ingwer');

INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnaehrungstrend, IstAktiv)
SELECT 'Bio-Kurkuma', 'Frische Kurkumawurzel - entzuendungshemmend und ein echter Trend.', 'Ernährungstrend', 2.49, 100, 'g', 1, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = 'Bio-Kurkuma');


-- 4. Kontrollabfrage
-- -------------------------------------------------------------------------------------
SELECT
    Kategorie,
    COUNT(*)                              AS AnzahlProdukte,
    SUM(CAST(IstErnaehrungstrend AS INT)) AS DavonTrends
FROM Produkt
GROUP BY Kategorie
ORDER BY Kategorie;

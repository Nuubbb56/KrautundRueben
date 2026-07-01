-- ============================================================
-- Kraut & Rüben – Komplette Datenbank-Setup (Einzeldatei)
-- Kombiniert: 01_KrautUndRuebenDB.sql, Datenbank_Setup.sql, Migration_Produkte_Erweiterung.sql
-- Schema passt zur C#-Applikation!
-- Encoding: UTF-8 mit BOM
-- ============================================================

IF DB_ID('KrautUndRuebenDB') IS NULL
BEGIN
    CREATE DATABASE KrautUndRuebenDB;
END
GO

USE KrautUndRuebenDB;
GO


-- ============================================================
-- 1. TABELLEN ERSTELLEN (Idempotent: Wenn bereits vorhanden, nicht überschreiben)
-- ============================================================

-- ── Kunde ──────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Kunde')
BEGIN
    CREATE TABLE Kunde
    (
        KundeID           INT IDENTITY(1,1) PRIMARY KEY,
        Vorname           NVARCHAR(100)  NOT NULL,
        Nachname          NVARCHAR(100)  NOT NULL,
        EMail             NVARCHAR(200)  NOT NULL,
        Telefon           NVARCHAR(50)   NULL,
        Adresse           NVARCHAR(300)  NULL,
        DatenschutzStatus NVARCHAR(50)   NOT NULL DEFAULT N'Aktiv',
        ErstelltAm        DATETIME2      NOT NULL DEFAULT SYSDATETIME()
    );
END
GO

-- ── Produkt ────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Produkt')
BEGIN
    CREATE TABLE Produkt
    (
        ProduktID            INT IDENTITY(1,1) PRIMARY KEY,
        Name                 NVARCHAR(150)  NOT NULL,
        Beschreibung         NVARCHAR(500)  NULL,
        Kategorie            NVARCHAR(100)  NOT NULL DEFAULT N'Bio-Box',
        Preis                DECIMAL(10,2)  NOT NULL,
        EinheitMenge         DECIMAL(10,3)  NOT NULL DEFAULT 1,
        EinheitTyp           NVARCHAR(20)   NOT NULL DEFAULT N'kg',
        IstErnährungstrend   BIT            NOT NULL DEFAULT 0,
        IstAktiv             BIT            NOT NULL DEFAULT 1
    );
END
GO

-- Fehlende Spalten ergänzen (für ältere Versionen)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Produkt' AND COLUMN_NAME = 'Kategorie')
    ALTER TABLE Produkt ADD Kategorie NVARCHAR(100) NOT NULL DEFAULT N'Bio-Box';

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Produkt' AND COLUMN_NAME = 'Beschreibung')
    ALTER TABLE Produkt ADD Beschreibung NVARCHAR(500) NULL;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Produkt' AND COLUMN_NAME = 'EinheitMenge')
    ALTER TABLE Produkt ADD EinheitMenge DECIMAL(10,3) NOT NULL DEFAULT 1;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Produkt' AND COLUMN_NAME = 'EinheitTyp')
    ALTER TABLE Produkt ADD EinheitTyp NVARCHAR(20) NOT NULL DEFAULT N'kg';

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Produkt' AND COLUMN_NAME = 'IstErnährungstrend')
    ALTER TABLE Produkt ADD IstErnährungstrend BIT NOT NULL DEFAULT 0;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Produkt' AND COLUMN_NAME = 'IstAktiv')
    ALTER TABLE Produkt ADD IstAktiv BIT NOT NULL DEFAULT 1;
GO

-- ── Bestellung ─────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Bestellung')
BEGIN
    CREATE TABLE Bestellung
    (
        BestellungID   INT IDENTITY(1,1) PRIMARY KEY,
        KundeID        INT NOT NULL REFERENCES Kunde(KundeID),
        Bestelldatum   DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
        Status         NVARCHAR(50)  NOT NULL DEFAULT N'Offen',
        Gesamtbetrag   DECIMAL(10,2) NOT NULL DEFAULT 0
    );
END
GO

-- ── Bestellposition ────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Bestellposition')
BEGIN
    CREATE TABLE Bestellposition
    (
        BestellpositionID INT IDENTITY(1,1) PRIMARY KEY,
        BestellungID      INT NOT NULL REFERENCES Bestellung(BestellungID),
        ProduktID         INT NOT NULL REFERENCES Produkt(ProduktID),
        Menge             DECIMAL(10,3)  NOT NULL DEFAULT 1,
        Einzelpreis       DECIMAL(10,2)  NOT NULL
    );
END
GO

-- ── Rechnung ───────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Rechnung')
BEGIN
    CREATE TABLE Rechnung
    (
        RechnungID      INT IDENTITY(1,1) PRIMARY KEY,
        BestellungID    INT NOT NULL REFERENCES Bestellung(BestellungID),
        Rechnungsnummer NVARCHAR(30)  NOT NULL UNIQUE,
        Rechnungsdatum  DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
        Betrag          DECIMAL(10,2) NOT NULL
    );
END
GO

-- ── DSGVO_Anfrage ──────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DSGVO_Anfrage')
BEGIN
    CREATE TABLE DSGVO_Anfrage
    (
        AnfrageID    INT IDENTITY(1,1) PRIMARY KEY,
        KundeID      INT NOT NULL REFERENCES Kunde(KundeID),
        Typ          NVARCHAR(30)   NOT NULL,   -- 'AUSKUNFT' oder 'LOESCHUNG'
        Bemerkung    NVARCHAR(500)  NULL,
        Status       NVARCHAR(30)   NOT NULL DEFAULT N'Offen',
        ErstelltAm   DATETIME2      NOT NULL DEFAULT SYSDATETIME()
    );
END
GO

-- ── AuditLog ───────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'AuditLog')
BEGIN
    CREATE TABLE AuditLog
    (
        LogID          INT IDENTITY(1,1) PRIMARY KEY,
        Aktion         NVARCHAR(100)  NOT NULL,
        KundeID        INT            NULL,
        BearbeitetVon  NVARCHAR(100)  NULL,
        Zeitpunkt      DATETIME2      NOT NULL DEFAULT SYSDATETIME(),
        Details        NVARCHAR(500)  NULL
    );
END
GO


-- ============================================================
-- 2. BASISDATEN EINFÜGEN (Idempotent)
-- ============================================================

-- ── Kunden ─────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM Kunde)
BEGIN
    INSERT INTO Kunde (Vorname, Nachname, EMail, Telefon, Adresse) VALUES
    (N'Anna', N'Meyer', N'anna.meyer@example.de', N'040111111', N'Musterweg 1, 20095 Hamburg'),
    (N'Lukas', N'Schmidt', N'lukas.schmidt@example.de', N'040222222', N'Hauptstr. 5, 20099 Hamburg'),
    (N'Sophie', N'Becker', N'sophie.becker@example.de', N'040333333', N'Elballee 10, 22767 Hamburg'),
    (N'Max', N'Fischer', N'max.fischer@example.de', NULL, N'Alsterufer 7, 20354 Hamburg'),
    (N'Laura', N'Weber', N'laura.weber@example.de', N'040555555', N'Gartenweg 22, 22335 Hamburg');
END
GO

-- ── Basisprodukte ──────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM Produkt)
BEGIN
    INSERT INTO Produkt (Name, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnährungstrend, IstAktiv) VALUES
    (N'Tomate Bio', N'Einzelgemüse', 2.49, 1, N'kg', 0, 1),
    (N'Kartoffel regional', N'Einzelgemüse', 1.99, 1, N'kg', 0, 1),
    (N'Apfel Elstar', N'Einzelobst', 3.49, 1, N'kg', 0, 1),
    (N'Basilikum Topf', N'Kräuter & Gewürze', 2.99, 1, N'Stück', 0, 1),
    (N'Karottensamen', N'Kräuter & Gewürze', 1.49, 1, N'Beutel', 0, 1),
    (N'Zucchini', N'Einzelgemüse', 2.79, 1, N'kg', 0, 1);
END
GO


-- ============================================================
-- 3. STORED PROCEDURES (DSGVO-Modul)
-- ============================================================

-- ── sp_DSGVO_AnfrageAnlegen ────────────────────────────────
CREATE OR ALTER PROCEDURE sp_DSGVO_AnfrageAnlegen
    @KundeID    INT,
    @Typ        NVARCHAR(30),
    @Bemerkung  NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO DSGVO_Anfrage (KundeID, Typ, Bemerkung, Status)
    VALUES (@KundeID, @Typ, @Bemerkung, N'Offen');

    INSERT INTO AuditLog (Aktion, KundeID, BearbeitetVon, Details)
    VALUES (N'DSGVO-Antrag angelegt: ' + @Typ, @KundeID, SYSTEM_USER, @Bemerkung);
END
GO

-- ── sp_DSGVO_Auskunft ──────────────────────────────────────
CREATE OR ALTER PROCEDURE sp_DSGVO_Auskunft
    @KundeID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT KundeID, Vorname, Nachname, EMail, Telefon, Adresse, DatenschutzStatus, ErstelltAm
    FROM Kunde
    WHERE KundeID = @KundeID;

    SELECT BestellungID, Bestelldatum, Status, Gesamtbetrag
    FROM Bestellung
    WHERE KundeID = @KundeID
    ORDER BY BestellungID;

    SELECT bp.BestellpositionID, bp.BestellungID, p.Name AS Produktname, bp.Menge, bp.Einzelpreis
    FROM Bestellposition bp
    INNER JOIN Bestellung b ON bp.BestellungID = b.BestellungID
    INNER JOIN Produkt p ON bp.ProduktID = p.ProduktID
    WHERE b.KundeID = @KundeID
    ORDER BY bp.BestellungID;

    SELECT r.RechnungID, r.BestellungID, r.Rechnungsnummer, r.Rechnungsdatum, r.Betrag
    FROM Rechnung r
    INNER JOIN Bestellung b ON r.BestellungID = b.BestellungID
    WHERE b.KundeID = @KundeID
    ORDER BY r.RechnungID;
END
GO

-- ── sp_DSGVO_LoescheKunde ──────────────────────────────────
CREATE OR ALTER PROCEDURE sp_DSGVO_LoescheKunde
    @KundeID        INT,
    @BearbeitetVon  NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM Bestellung b
        INNER JOIN Rechnung r ON r.BestellungID = b.BestellungID
        WHERE b.KundeID = @KundeID
    )
    BEGIN
        UPDATE Kunde
        SET Vorname           = N'Anonymisiert',
            Nachname           = N'Anonymisiert',
            EMail              = CONCAT(N'geloescht_', KundeID, N'@anonym.invalid'),
            Telefon            = NULL,
            Adresse            = NULL,
            DatenschutzStatus  = N'Anonymisiert'
        WHERE KundeID = @KundeID;

        INSERT INTO AuditLog (Aktion, KundeID, BearbeitetVon, Details)
        VALUES (N'Kunde anonymisiert (Aufbewahrungspflicht)', @KundeID, @BearbeitetVon,
                N'Rechnungsdaten vorhanden – vollständige Löschung nicht zulässig.');
    END
    ELSE
    BEGIN
        DELETE FROM DSGVO_Anfrage WHERE KundeID = @KundeID;
        DELETE FROM Kunde WHERE KundeID = @KundeID;

        INSERT INTO AuditLog (Aktion, KundeID, BearbeitetVon, Details)
        VALUES (N'Kunde vollständig gelöscht', @KundeID, @BearbeitetVon, NULL);
    END
END
GO


-- ============================================================
-- 4. ERWEITERTES PRODUKTSORTIMENT (Boxen & Ernährungstrends)
-- ============================================================
UPDATE Produkt SET Kategorie = N'Bio-Box', IstAktiv = 1 WHERE Kategorie IS NULL OR Kategorie = N'';

-- ── Bio-Boxen ──────────────────────────────────────────────
INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnährungstrend, IstAktiv)
SELECT N'Bio-Box Classic', N'Gemischte saisonale Gemüse- und Obstselektion in Bio-Qualität.', N'Bio-Box', 24.90, 1, N'Box', 0, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = N'Bio-Box Classic');

INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnährungstrend, IstAktiv)
SELECT N'Bio-Box Family', N'Größere Familienbox mit mehr Vielfalt – ideal für 3 bis 4 Personen.', N'Bio-Box', 38.90, 1, N'Box', 0, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = N'Bio-Box Family');

INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnährungstrend, IstAktiv)
SELECT N'Bio-Box Mini', N'Kompakte Einsteiger-Box für 1 bis 2 Personen pro Woche.', N'Bio-Box', 14.90, 1, N'Box', 0, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = N'Bio-Box Mini');

-- ── Gemüse-Boxen ───────────────────────────────────────────
INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnährungstrend, IstAktiv)
SELECT N'Gemüse-Box Standard', N'Saisonales Gemüse aus regionalem Bio-Anbau.', N'Gemüse-Box', 19.90, 1, N'Box', 0, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = N'Gemüse-Box Standard');

INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnährungstrend, IstAktiv)
SELECT N'Rohkost-Box', N'Perfekt für die Rohkost-Ernährung: Karotten, Kohlrabi, Sellerie, Rote Bete.', N'Rohkost-Box', 22.50, 1, N'Box', 1, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = N'Rohkost-Box');

-- ── Obst-Box ───────────────────────────────────────────────
INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnährungstrend, IstAktiv)
SELECT N'Obst-Box Classic', N'Saisonale Obstauswahl in zertifizierter Bio-Qualität.', N'Obst-Box', 21.90, 1, N'Box', 0, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = N'Obst-Box Classic');

-- ── Kräuter-Box ────────────────────────────────────────────
INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnährungstrend, IstAktiv)
SELECT N'Kräuter-Box Premium', N'Frische Küchenkräuter: Basilikum, Rosmarin, Thymian, Petersilie, Minze.', N'Kräuter-Box', 12.90, 1, N'Box', 0, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = N'Kräuter-Box Premium');

-- ── Ernährungstrend-Produkte ───────────────────────────────
INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnährungstrend, IstAktiv)
SELECT N'Superfood-Box', N'Brokkoli, Spinat, Grünkohl, Chia-Samen – reich an Antioxidantien und Nährstoffen.', N'Superfood-Box', 29.90, 1, N'Box', 1, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = N'Superfood-Box');

INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnährungstrend, IstAktiv)
SELECT N'Detox-Box', N'Entgiftend: Ingwer, Kurkuma, Petersilie, Gurke, Zitrone – alles in Bio-Qualität.', N'Ernährungstrend', 27.50, 1, N'Box', 1, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = N'Detox-Box');

INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnährungstrend, IstAktiv)
SELECT N'Fermentier-Box', N'Alles für Fermentation: Weißkohl, Rotkohl, Rüben, Chinakohl – darmfreundlich.', N'Ernährungstrend', 18.90, 1, N'Box', 1, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = N'Fermentier-Box');

-- ── Saisonale Boxen ────────────────────────────────────────
INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnährungstrend, IstAktiv)
SELECT N'Saisonale Box Sommer', N'Tomaten, Zucchini, Paprika, Gurken – frisch aus der Sommersaison.', N'Saisonale Box', 20.90, 1, N'Box', 0, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = N'Saisonale Box Sommer');

INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnährungstrend, IstAktiv)
SELECT N'Saisonale Box Herbst', N'Kürbis, Sellerie, Pastinaken, Rote Bete – typisch für die Herbstsaison.', N'Saisonale Box', 20.90, 1, N'Box', 0, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = N'Saisonale Box Herbst');

-- ── Einzelprodukte ─────────────────────────────────────────
INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnährungstrend, IstAktiv)
SELECT N'Bio-Möhren', N'Frische Bio-Karotten, lose, knackig und süß.', N'Einzelgemüse', 2.49, 1, N'kg', 0, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = N'Bio-Möhren');

INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnährungstrend, IstAktiv)
SELECT N'Bio-Ingwer', N'Frischer Bio-Ingwer – Trend-Zutat für Tee, Smoothies und Küche.', N'Ernährungstrend', 1.99, 100, N'g', 1, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = N'Bio-Ingwer');

INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnährungstrend, IstAktiv)
SELECT N'Bio-Kurkuma', N'Frische Kurkumawurzel – entzündungshemmend und ein echter Trend.', N'Ernährungstrend', 2.49, 100, N'g', 1, 1
WHERE NOT EXISTS (SELECT 1 FROM Produkt WHERE Name = N'Bio-Kurkuma');
GO


-- ============================================================
-- 5. BEISPIELBESTELLUNGEN UND RECHNUNGEN
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM Bestellung)
BEGIN
    INSERT INTO Bestellung (KundeID, Bestelldatum, Status, Gesamtbetrag) VALUES
    (1, '2026-05-01', N'Bezahlt', 45.80),
    (1, '2026-05-15', N'Versendet', 38.90),
    (2, '2026-05-10', N'Bezahlt', 85.40),
    (3, '2026-05-20', N'Offen', 15.90);

    INSERT INTO Bestellposition (BestellungID, ProduktID, Menge, Einzelpreis) VALUES
    (1, 1, 1, 2.49), (1, 4, 1, 2.99), (1, 5, 3, 1.49),
    (2, 7, 1, 38.90),
    (3, 2, 2, 1.99), (3, 6, 1, 2.79),
    (4, 3, 2, 3.49), (4, 1, 1, 2.49), (4, 4, 2, 2.99);

    INSERT INTO Rechnung (BestellungID, Rechnungsnummer, Rechnungsdatum, Betrag) VALUES
    (1, N'KR-2026-0001', '2026-05-01', 45.80),
    (2, N'KR-2026-0002', '2026-05-15', 38.90),
    (3, N'KR-2026-0003', '2026-05-10', 85.40);
END
GO


-- ============================================================
-- 6. VIEW: DSGVO_Anfragen mit Kundennamen
-- ============================================================
CREATE OR ALTER VIEW v_DSGVO_Anfragen
AS
SELECT
    a.AnfrageID,
    a.KundeID,
    k.Vorname,
    k.Nachname,
    a.Typ,
    a.Bemerkung,
    a.Status,
    a.ErstelltAm
FROM DSGVO_Anfrage a
INNER JOIN Kunde k ON a.KundeID = k.KundeID;
GO


PRINT 'Datenbank erfolgreich erstellt!';

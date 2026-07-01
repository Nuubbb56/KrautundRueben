-- ============================================
-- Kraut & Rüben - Komplette Datenbank-Setup
-- Kombiniert: 01_KrautUndRuebenDB.sql, Datenbank_Setup.sql, Migration_Produkte_Erweiterung.sql
-- UTF-8 mit BOM
-- ============================================

IF DB_ID('KrautUndRuebenDB') IS NULL
BEGIN
    CREATE DATABASE KrautUndRuebenDB;
END
GO

USE KrautUndRuebenDB;
GO

-- ============================================
-- Aufräumen (idempotent)
-- ============================================

IF OBJECT_ID('sp_DSGVO_LoescheKunde', 'P') IS NOT NULL DROP PROCEDURE sp_DSGVO_LoescheKunde;
IF OBJECT_ID('sp_DSGVO_Auskunft', 'P') IS NOT NULL DROP PROCEDURE sp_DSGVO_Auskunft;
IF OBJECT_ID('sp_DSGVO_AnfrageAnlegen', 'P') IS NOT NULL DROP PROCEDURE sp_DSGVO_AnfrageAnlegen;
IF OBJECT_ID('sp_AuditLogEintrag', 'P') IS NOT NULL DROP PROCEDURE sp_AuditLogEintrag;
GO

IF OBJECT_ID('v_DSGVO_Anfragen', 'V') IS NOT NULL DROP VIEW v_DSGVO_Anfragen;
IF OBJECT_ID('v_RechnungMitBetrag', 'V') IS NOT NULL DROP VIEW v_RechnungMitBetrag;
IF OBJECT_ID('v_BestellungMitGesamtbetrag', 'V') IS NOT NULL DROP VIEW v_BestellungMitGesamtbetrag;
IF OBJECT_ID('v_KundeMitAdresse', 'V') IS NOT NULL DROP VIEW v_KundeMitAdresse;
GO

IF OBJECT_ID('dbo.fn_Bestellwert', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_Bestellwert;
GO

IF OBJECT_ID('AuditLog', 'U') IS NOT NULL DROP TABLE AuditLog;
IF OBJECT_ID('DSGVO_Anfrage', 'U') IS NOT NULL DROP TABLE DSGVO_Anfrage;
IF OBJECT_ID('Rechnung', 'U') IS NOT NULL DROP TABLE Rechnung;
IF OBJECT_ID('Bestellposition', 'U') IS NOT NULL DROP TABLE Bestellposition;
IF OBJECT_ID('Bestellung', 'U') IS NOT NULL DROP TABLE Bestellung;
IF OBJECT_ID('Produkt', 'U') IS NOT NULL DROP TABLE Produkt;
IF OBJECT_ID('Kategorie', 'U') IS NOT NULL DROP TABLE Kategorie;
IF OBJECT_ID('KundenAdresse', 'U') IS NOT NULL DROP TABLE KundenAdresse;
IF OBJECT_ID('Kunde', 'U') IS NOT NULL DROP TABLE Kunde;
IF OBJECT_ID('DSGVO_AnfrageStatus', 'U') IS NOT NULL DROP TABLE DSGVO_AnfrageStatus;
IF OBJECT_ID('DSGVO_AnfrageTyp', 'U') IS NOT NULL DROP TABLE DSGVO_AnfrageTyp;
IF OBJECT_ID('BestellungStatus', 'U') IS NOT NULL DROP TABLE BestellungStatus;
IF OBJECT_ID('DatenschutzStatus', 'U') IS NOT NULL DROP TABLE DatenschutzStatus;
GO

-- ============================================
-- Tabellen erzeugen (3NF)
-- ============================================

CREATE TABLE DatenschutzStatus (
    DatenschutzStatusID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE BestellungStatus (
    BestellungStatusID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE DSGVO_AnfrageTyp (
    TypID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE DSGVO_AnfrageStatus (
    StatusID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE Kategorie (
    KategorieID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Kunde (
    KundeID INT IDENTITY(1,1) PRIMARY KEY,
    Vorname NVARCHAR(100) NOT NULL,
    Nachname NVARCHAR(100) NOT NULL,
    EMail NVARCHAR(200) NOT NULL UNIQUE,
    Telefon NVARCHAR(50) NULL,
    Erstellungsdatum DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    DatenschutzStatusID INT NOT NULL DEFAULT 1,
    GeloeschtAm DATETIME2 NULL,
    CONSTRAINT FK_Kunde_DatenschutzStatus FOREIGN KEY (DatenschutzStatusID) REFERENCES DatenschutzStatus(DatenschutzStatusID)
);

CREATE TABLE KundenAdresse (
    KundenAdresseID INT IDENTITY(1,1) PRIMARY KEY,
    KundeID INT NOT NULL UNIQUE,
    StrasseHausnummer NVARCHAR(150) NULL,
    PLZ NVARCHAR(10) NULL,
    Ort NVARCHAR(100) NULL,
    CONSTRAINT FK_KundenAdresse_Kunde FOREIGN KEY (KundeID) REFERENCES Kunde(KundeID) ON DELETE CASCADE
);

CREATE TABLE Produkt (
    ProduktID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(150) NOT NULL,
    Beschreibung NVARCHAR(500) NULL,
    KategorieID INT NOT NULL,
    Preis DECIMAL(10,2) NOT NULL,
    EinheitMenge DECIMAL(10,3) NOT NULL DEFAULT 1,
    EinheitTyp NVARCHAR(20) NOT NULL DEFAULT N'kg',
    IstErnährungstrend BIT NOT NULL DEFAULT 0,
    IstAktiv BIT NOT NULL DEFAULT 1,
    Lagerbestand INT NOT NULL DEFAULT 0,
    CONSTRAINT CK_Produkt_Preis CHECK (Preis >= 0),
    CONSTRAINT CK_Produkt_Lagerbestand CHECK (Lagerbestand >= 0),
    CONSTRAINT FK_Produkt_Kategorie FOREIGN KEY (KategorieID) REFERENCES Kategorie(KategorieID)
);

CREATE TABLE Bestellung (
    BestellungID INT IDENTITY(1,1) PRIMARY KEY,
    KundeID INT NOT NULL,
    Bestelldatum DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    BestellungStatusID INT NOT NULL,
    CONSTRAINT FK_Bestellung_Kunde FOREIGN KEY (KundeID) REFERENCES Kunde(KundeID),
    CONSTRAINT FK_Bestellung_Status FOREIGN KEY (BestellungStatusID) REFERENCES BestellungStatus(BestellungStatusID)
);

CREATE TABLE Bestellposition (
    BestellpositionID INT IDENTITY(1,1) PRIMARY KEY,
    BestellungID INT NOT NULL,
    ProduktID INT NOT NULL,
    Menge DECIMAL(10,3) NOT NULL DEFAULT 1,
    Einzelpreis DECIMAL(10,2) NOT NULL,
    CONSTRAINT CK_Bestellposition_Menge CHECK (Menge > 0),
    CONSTRAINT CK_Bestellposition_Einzelpreis CHECK (Einzelpreis >= 0),
    CONSTRAINT FK_Bestellposition_Bestellung FOREIGN KEY (BestellungID) REFERENCES Bestellung(BestellungID) ON DELETE CASCADE,
    CONSTRAINT FK_Bestellposition_Produkt FOREIGN KEY (ProduktID) REFERENCES Produkt(ProduktID)
);

CREATE TABLE Rechnung (
    RechnungID INT IDENTITY(1,1) PRIMARY KEY,
    BestellungID INT NOT NULL UNIQUE,
    Rechnungsnummer NVARCHAR(30) NOT NULL UNIQUE,
    Rechnungsdatum DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Rechnung_Bestellung FOREIGN KEY (BestellungID) REFERENCES Bestellung(BestellungID)
);

CREATE TABLE DSGVO_Anfrage (
    AnfrageID INT IDENTITY(1,1) PRIMARY KEY,
    KundeID INT NOT NULL,
    TypID INT NOT NULL,
    Eingangsdatum DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    StatusID INT NOT NULL,
    BearbeitetAm DATETIME2 NULL,
    BearbeitetVon NVARCHAR(100) NULL,
    Bemerkung NVARCHAR(500) NULL,
    CONSTRAINT FK_DSGVO_Anfrage_Kunde FOREIGN KEY (KundeID) REFERENCES Kunde(KundeID),
    CONSTRAINT FK_DSGVO_Anfrage_Typ FOREIGN KEY (TypID) REFERENCES DSGVO_AnfrageTyp(TypID),
    CONSTRAINT FK_DSGVO_Anfrage_Status FOREIGN KEY (StatusID) REFERENCES DSGVO_AnfrageStatus(StatusID)
);

CREATE TABLE AuditLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    KundeID INT NULL,
    Aktion NVARCHAR(100) NOT NULL,
    Zeitpunkt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Benutzer NVARCHAR(100) NOT NULL,
    Details NVARCHAR(1000) NULL,
    CONSTRAINT FK_AuditLog_Kunde FOREIGN KEY (KundeID) REFERENCES Kunde(KundeID) ON DELETE SET NULL
);
GO

-- ============================================
-- Basisdaten einfügen
-- ============================================

INSERT INTO DatenschutzStatus (Name) VALUES (N'Aktiv'), (N'Gelöscht'), (N'Anonymisiert');
INSERT INTO BestellungStatus (Name) VALUES (N'Offen'), (N'Bezahlt'), (N'Versendet'), (N'Storniert');
INSERT INTO DSGVO_AnfrageTyp (Name) VALUES (N'AUSKUNFT'), (N'LOESCHUNG');
INSERT INTO DSGVO_AnfrageStatus (Name) VALUES (N'Offen'), (N'Erledigt');

INSERT INTO Kategorie (Name) VALUES
    (N'Bio-Box'),
    (N'Gemüse-Box'),
    (N'Obst-Box'),
    (N'Kräuter-Box'),
    (N'Superfood-Box'),
    (N'Rohkost-Box'),
    (N'Saisonale Box'),
    (N'Einzelgemüse'),
    (N'Einzelobst'),
    (N'Kräuter & Gewürze'),
    (N'Ernährungstrend');
GO

-- ============================================
-- Produkt-Daten einfügen (aus Migration & Setup)
-- ============================================

INSERT INTO Produkt (Name, Beschreibung, KategorieID, Preis, EinheitMenge, EinheitTyp, IstErnährungstrend, IstAktiv, Lagerbestand) VALUES
-- Bio-Boxen
(N'Bio-Box Classic', N'Gemischte saisonale Gemüse- und Obstselektion in Bio-Qualität.', (SELECT KategorieID FROM Kategorie WHERE Name = N'Bio-Box'), 24.90, 1, N'Box', 0, 1, 50),
(N'Bio-Box Family', N'Größere Familienbox für 3-4 Personen mit mehr Vielfalt.', (SELECT KategorieID FROM Kategorie WHERE Name = N'Bio-Box'), 38.90, 1, N'Box', 0, 1, 30),
(N'Bio-Box Mini', N'Kompakte Einsteiger-Box für 1-2 Personen pro Woche.', (SELECT KategorieID FROM Kategorie WHERE Name = N'Bio-Box'), 14.90, 1, N'Box', 0, 1, 40),

-- Gemüse-Boxen
(N'Gemüse-Box Standard', N'Saisonales Gemüse aus regionalem Bio-Anbau.', (SELECT KategorieID FROM Kategorie WHERE Name = N'Gemüse-Box'), 19.90, 1, N'Box', 0, 1, 35),
(N'Rohkost-Box', N'Perfekt für Rohkost-Ernährung: Karotten, Kohlrabi, Sellerie, Rote Bete.', (SELECT KategorieID FROM Kategorie WHERE Name = N'Rohkost-Box'), 22.50, 1, N'Box', 1, 1, 25),

-- Obst-Box
(N'Obst-Box Classic', N'Saisonale Obstauswahl in zertifizierter Bio-Qualität.', (SELECT KategorieID FROM Kategorie WHERE Name = N'Obst-Box'), 21.90, 1, N'Box', 0, 1, 45),

-- Kräuter-Box
(N'Kräuter-Box Premium', N'Frische Küchenkräuter: Basilikum, Rosmarin, Thymian, Petersilie, Minze.', (SELECT KategorieID FROM Kategorie WHERE Name = N'Kräuter-Box'), 12.90, 1, N'Box', 0, 1, 60),

-- Ernährungstrend Produkte
(N'Superfood-Box', N'Brokkoli, Spinat, Grünkohl, Chia-Samen – reich an Antioxidantien.', (SELECT KategorieID FROM Kategorie WHERE Name = N'Superfood-Box'), 29.90, 1, N'Box', 1, 1, 20),
(N'Detox-Box', N'Entgiftend: Ingwer, Kurkuma, Petersilie, Gurke, Zitrone – alles in Bio-Qualität.', (SELECT KategorieID FROM Kategorie WHERE Name = N'Ernährungstrend'), 27.50, 1, N'Box', 1, 1, 22),
(N'Fermentier-Box', N'Alles für Fermentation: Weißkohl, Rotkohl, Rüben, Chinakohl – darmfreundlich.', (SELECT KategorieID FROM Kategorie WHERE Name = N'Ernährungstrend'), 18.90, 1, N'Box', 1, 1, 28),

-- Saisonale Boxen
(N'Saisonale Box Sommer', N'Tomaten, Zucchini, Paprika, Gurken – frisch aus der Sommersaison.', (SELECT KategorieID FROM Kategorie WHERE Name = N'Saisonale Box'), 20.90, 1, N'Box', 0, 1, 30),
(N'Saisonale Box Herbst', N'Kürbis, Sellerie, Pastinaken, Rote Bete – typisch für die Herbstsaison.', (SELECT KategorieID FROM Kategorie WHERE Name = N'Saisonale Box'), 20.90, 1, N'Box', 0, 1, 28),

-- Einzelprodukte
(N'Tomate Bio', N'Frische Bio-Tomaten', (SELECT KategorieID FROM Kategorie WHERE Name = N'Einzelgemüse'), 2.49, 1, N'kg', 0, 1, 100),
(N'Kartoffel regional', N'Regionale Kartoffeln', (SELECT KategorieID FROM Kategorie WHERE Name = N'Einzelgemüse'), 1.99, 1, N'kg', 0, 1, 200),
(N'Apfel Elstar', N'Frische Bio-Äpfel Elstar', (SELECT KategorieID FROM Kategorie WHERE Name = N'Einzelobst'), 3.49, 1, N'kg', 0, 1, 150),
(N'Basilikum Topf', N'Frischer Basilikum im Topf', (SELECT KategorieID FROM Kategorie WHERE Name = N'Kräuter & Gewürze'), 2.99, 1, N'Stück', 0, 1, 50),
(N'Karottensamen', N'Bio-Karottensamen', (SELECT KategorieID FROM Kategorie WHERE Name = N'Kräuter & Gewürze'), 1.49, 1, N'Beutel', 0, 1, 80),
(N'Zucchini', N'Frische Bio-Zucchini', (SELECT KategorieID FROM Kategorie WHERE Name = N'Einzelgemüse'), 2.79, 1, N'kg', 0, 1, 120),
(N'Bio-Möhren', N'Frische Bio-Karotten, lose, knackig und süß.', (SELECT KategorieID FROM Kategorie WHERE Name = N'Einzelgemüse'), 2.49, 1, N'kg', 0, 1, 110),
(N'Bio-Ingwer', N'Frischer Bio-Ingwer – Trend-Zutat für Tee, Smoothies und Küche.', (SELECT KategorieID FROM Kategorie WHERE Name = N'Ernährungstrend'), 1.99, 100, N'g', 1, 1, 75),
(N'Bio-Kurkuma', N'Frische Kurkumawurzel – entzündungshemmend und ein echter Trend.', (SELECT KategorieID FROM Kategorie WHERE Name = N'Ernährungstrend'), 2.49, 100, N'g', 1, 1, 70);
GO

-- ============================================
-- Beispieldaten für Kunden, Adressen, Bestellungen
-- ============================================

INSERT INTO Kunde (Vorname, Nachname, EMail, Telefon) VALUES
(N'Anna', N'Meyer', N'anna.meyer@example.de', N'040111111'),
(N'Lukas', N'Schmidt', N'lukas.schmidt@example.de', N'040222222'),
(N'Sophie', N'Becker', N'sophie.becker@example.de', N'040333333'),
(N'Max', N'Fischer', N'max.fischer@example.de', NULL),
(N'Laura', N'Weber', N'laura.weber@example.de', N'040555555');

INSERT INTO KundenAdresse (KundeID, StrasseHausnummer, PLZ, Ort) VALUES
(1, N'Musterweg 1', N'20095', N'Hamburg'),
(2, N'Hauptstr. 5', N'20099', N'Hamburg'),
(3, N'Elballee 10', N'22767', N'Hamburg'),
(4, N'Alsterufer 7', N'20354', N'Hamburg'),
(5, N'Gartenweg 22', N'22335', N'Hamburg');

DECLARE @StatusOffen INT = (SELECT BestellungStatusID FROM BestellungStatus WHERE Name = N'Offen');
DECLARE @StatusBezahlt INT = (SELECT BestellungStatusID FROM BestellungStatus WHERE Name = N'Bezahlt');
DECLARE @StatusVersendet INT = (SELECT BestellungStatusID FROM BestellungStatus WHERE Name = N'Versendet');

INSERT INTO Bestellung (KundeID, Bestelldatum, BestellungStatusID) VALUES
(1, '2026-05-01', @StatusBezahlt),
(1, '2026-05-15', @StatusVersendet),
(2, '2026-05-10', @StatusBezahlt),
(3, '2026-05-20', @StatusOffen);

-- Einfache Bestellpositionen
INSERT INTO Bestellposition (BestellungID, ProduktID, Menge, Einzelpreis) VALUES
(1, (SELECT ProduktID FROM Produkt WHERE Name = N'Bio-Box Classic'), 1, 24.90),
(1, (SELECT ProduktID FROM Produkt WHERE Name = N'Bio-Möhren'), 1, 2.49),
(2, (SELECT ProduktID FROM Produkt WHERE Name = N'Bio-Box Family'), 1, 38.90),
(3, (SELECT ProduktID FROM Produkt WHERE Name = N'Bio-Box Mini'), 1, 14.90),
(4, (SELECT ProduktID FROM Produkt WHERE Name = N'Gemüse-Box Standard'), 1, 19.90);

INSERT INTO Rechnung (BestellungID, Rechnungsnummer, Rechnungsdatum) VALUES
(1, N'KR-2026-0001', '2026-05-01'),
(2, N'KR-2026-0002', '2026-05-15'),
(3, N'KR-2026-0003', '2026-05-10');
GO

-- ============================================
-- Funktionen, Views, Stored Procedures
-- ============================================

CREATE FUNCTION dbo.fn_Bestellwert (@BestellungID INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Betrag DECIMAL(10,2);

    SELECT @Betrag = CAST(ISNULL(SUM(CAST(Menge AS DECIMAL(10,2)) * Einzelpreis), 0) AS DECIMAL(10,2))
    FROM Bestellposition
    WHERE BestellungID = @BestellungID;

    RETURN @Betrag;
END;
GO

CREATE VIEW v_KundeMitAdresse
AS
SELECT
    k.KundeID,
    k.Vorname,
    k.Nachname,
    k.EMail,
    k.Telefon,
    ka.StrasseHausnummer,
    ka.PLZ,
    ka.Ort,
    NULLIF(LTRIM(RTRIM(CONCAT(
        COALESCE(ka.StrasseHausnummer, ''),
        CASE WHEN ka.StrasseHausnummer IS NOT NULL AND (ka.PLZ IS NOT NULL OR ka.Ort IS NOT NULL) THEN N', ' ELSE N'' END,
        COALESCE(ka.PLZ, ''),
        CASE WHEN ka.PLZ IS NOT NULL AND ka.Ort IS NOT NULL THEN N' ' ELSE N'' END,
        COALESCE(ka.Ort, '')
    ))), N'') AS Adresse,
    k.Erstellungsdatum,
    ds.Name AS DatenschutzStatus,
    k.GeloeschtAm,
    CONCAT(k.Vorname, N' ', k.Nachname) AS Vollname
FROM Kunde k
INNER JOIN DatenschutzStatus ds ON k.DatenschutzStatusID = ds.DatenschutzStatusID
LEFT JOIN KundenAdresse ka ON k.KundeID = ka.KundeID;
GO

CREATE VIEW v_BestellungMitGesamtbetrag
AS
SELECT
    b.BestellungID,
    b.KundeID,
    b.Bestelldatum,
    bs.Name AS Status,
    dbo.fn_Bestellwert(b.BestellungID) AS Gesamtbetrag
FROM Bestellung b
INNER JOIN BestellungStatus bs ON b.BestellungStatusID = bs.BestellungStatusID;
GO

CREATE VIEW v_RechnungMitBetrag
AS
SELECT
    r.RechnungID,
    r.BestellungID,
    r.Rechnungsnummer,
    r.Rechnungsdatum,
    dbo.fn_Bestellwert(r.BestellungID) AS Betrag
FROM Rechnung r;
GO

CREATE VIEW v_DSGVO_Anfragen
AS
SELECT
    a.AnfrageID,
    a.KundeID,
    t.Name AS Typ,
    a.Eingangsdatum,
    s.Name AS Status,
    a.BearbeitetAm,
    a.BearbeitetVon,
    a.Bemerkung
FROM DSGVO_Anfrage a
INNER JOIN DSGVO_AnfrageTyp t ON a.TypID = t.TypID
INNER JOIN DSGVO_AnfrageStatus s ON a.StatusID = s.StatusID;
GO

CREATE PROCEDURE sp_AuditLogEintrag
    @KundeID INT = NULL,
    @Aktion NVARCHAR(100),
    @Benutzer NVARCHAR(100),
    @Details NVARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO AuditLog (KundeID, Aktion, Benutzer, Details)
    VALUES (@KundeID, @Aktion, @Benutzer, @Details);
END;
GO

CREATE PROCEDURE sp_DSGVO_AnfrageAnlegen
    @KundeID INT,
    @Typ NVARCHAR(20),
    @Bemerkung NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TypID INT = (SELECT TypID FROM DSGVO_AnfrageTyp WHERE Name = @Typ);
    DECLARE @StatusOffenID INT = (SELECT StatusID FROM DSGVO_AnfrageStatus WHERE Name = N'Offen');

    IF @TypID IS NULL
    BEGIN
        THROW 50001, N'Unbekannter DSGVO-Anfragetyp.', 1;
    END;

    INSERT INTO DSGVO_Anfrage (KundeID, TypID, StatusID, Bemerkung)
    VALUES (@KundeID, @TypID, @StatusOffenID, @Bemerkung);

    EXEC sp_AuditLogEintrag @KundeID, N'DSGVO-Antrag angelegt', SYSTEM_USER, CONCAT(N'Typ: ', @Typ);
END;
GO

CREATE PROCEDURE sp_DSGVO_Auskunft
    @KundeID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT KundeID, Vorname, Nachname, EMail, Telefon, Adresse, Erstellungsdatum, DatenschutzStatus, GeloeschtAm
    FROM v_KundeMitAdresse
    WHERE KundeID = @KundeID;

    SELECT BestellungID, Bestelldatum, Status, Gesamtbetrag
    FROM v_BestellungMitGesamtbetrag
    WHERE KundeID = @KundeID
    ORDER BY Bestelldatum;

    SELECT bp.BestellpositionID, bp.BestellungID, p.Name AS Produktname, bp.Menge, bp.Einzelpreis
    FROM Bestellposition bp
    INNER JOIN Produkt p ON bp.ProduktID = p.ProduktID
    INNER JOIN Bestellung b ON bp.BestellungID = b.BestellungID
    WHERE b.KundeID = @KundeID
    ORDER BY bp.BestellungID;

    SELECT r.RechnungID, r.BestellungID, r.Rechnungsnummer, r.Rechnungsdatum, r.Betrag
    FROM v_RechnungMitBetrag r
    INNER JOIN Bestellung b ON r.BestellungID = b.BestellungID
    WHERE b.KundeID = @KundeID
    ORDER BY r.Rechnungsdatum;
END;
GO

CREATE PROCEDURE sp_DSGVO_LoescheKunde
    @KundeID INT,
    @BearbeitetVon NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @HatRechnungen INT = 0;
    DECLARE @HatBestellungen INT = 0;
    DECLARE @StatusAnonymisiertID INT = (SELECT DatenschutzStatusID FROM DatenschutzStatus WHERE Name = N'Anonymisiert');
    DECLARE @TypLoeschungID INT = (SELECT TypID FROM DSGVO_AnfrageTyp WHERE Name = N'LOESCHUNG');
    DECLARE @StatusOffenID INT = (SELECT StatusID FROM DSGVO_AnfrageStatus WHERE Name = N'Offen');
    DECLARE @StatusErledigtID INT = (SELECT StatusID FROM DSGVO_AnfrageStatus WHERE Name = N'Erledigt');

    SELECT @HatRechnungen = COUNT(*)
    FROM Rechnung r
    INNER JOIN Bestellung b ON r.BestellungID = b.BestellungID
    WHERE b.KundeID = @KundeID;

    SELECT @HatBestellungen = COUNT(*)
    FROM Bestellung
    WHERE KundeID = @KundeID;

    IF @HatBestellungen = 0 AND @HatRechnungen = 0
    BEGIN
        EXEC sp_AuditLogEintrag @KundeID, N'Kunde vollständig gelöscht', @BearbeitetVon, N'Keine Bestellungen/Rechnungen vorhanden';

        DELETE FROM DSGVO_Anfrage WHERE KundeID = @KundeID;
        DELETE FROM Kunde WHERE KundeID = @KundeID;
    END
    ELSE
    BEGIN
        UPDATE Kunde
        SET Vorname = N'Anonymisiert',
            Nachname = N'Anonymisiert',
            EMail = CONCAT(N'geloescht_', @KundeID, N'@anonym.invalid'),
            Telefon = NULL,
            DatenschutzStatusID = @StatusAnonymisiertID,
            GeloeschtAm = SYSDATETIME()
        WHERE KundeID = @KundeID;

        UPDATE KundenAdresse
        SET StrasseHausnummer = NULL,
            PLZ = NULL,
            Ort = NULL
        WHERE KundeID = @KundeID;

        UPDATE DSGVO_Anfrage
        SET StatusID = @StatusErledigtID, BearbeitetAm = SYSDATETIME(), BearbeitetVon = @BearbeitetVon
        WHERE KundeID = @KundeID AND TypID = @TypLoeschungID AND StatusID = @StatusOffenID;

        EXEC sp_AuditLogEintrag @KundeID, N'Kunde anonymisiert', @BearbeitetVon, N'Bestellungen/Rechnungen vorhanden';
    END
END;
GO

PRINT N'Datenbank erfolgreich erstellt!';

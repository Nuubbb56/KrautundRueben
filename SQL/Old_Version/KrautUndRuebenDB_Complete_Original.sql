-- ============================================
-- Kraut & Rüben - Komplette Datenbank-Setup
-- Kombiniert alle 3 Original-SQL-Dateien
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
GO

IF OBJECT_ID('AuditLog', 'U') IS NOT NULL DROP TABLE AuditLog;
IF OBJECT_ID('DSGVO_Anfrage', 'U') IS NOT NULL DROP TABLE DSGVO_Anfrage;
IF OBJECT_ID('DSGVO_AnfrageStatus', 'U') IS NOT NULL DROP TABLE DSGVO_AnfrageStatus;
IF OBJECT_ID('DSGVO_AnfrageTyp', 'U') IS NOT NULL DROP TABLE DSGVO_AnfrageTyp;
IF OBJECT_ID('Rechnung', 'U') IS NOT NULL DROP TABLE Rechnung;
IF OBJECT_ID('Bestellposition', 'U') IS NOT NULL DROP TABLE Bestellposition;
IF OBJECT_ID('Bestellung', 'U') IS NOT NULL DROP TABLE Bestellung;
IF OBJECT_ID('Produkt', 'U') IS NOT NULL DROP TABLE Produkt;
IF OBJECT_ID('Kunde', 'U') IS NOT NULL DROP TABLE Kunde;
IF OBJECT_ID('BestellungStatus', 'U') IS NOT NULL DROP TABLE BestellungStatus;
IF OBJECT_ID('DatenschutzStatus', 'U') IS NOT NULL DROP TABLE DatenschutzStatus;
GO

-- ============================================
-- Tabellen erzeugen
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

CREATE TABLE Kunde (
    KundeID INT IDENTITY(1,1) PRIMARY KEY,
    Vorname NVARCHAR(100) NOT NULL,
    Nachname NVARCHAR(100) NOT NULL,
    EMail NVARCHAR(200) NOT NULL UNIQUE,
    Telefon NVARCHAR(50) NULL,
    Adresse NVARCHAR(250) NULL,
    Erstellungsdatum DATETIME NOT NULL DEFAULT GETDATE(),
    DatenschutzStatus NVARCHAR(50) NOT NULL DEFAULT 'Aktiv',
    GeloeschtAm DATETIME NULL
);

CREATE TABLE Produkt (
    ProduktID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(150) NOT NULL,
    Beschreibung NVARCHAR(500) NULL,
    Kategorie NVARCHAR(100) NOT NULL,
    Preis DECIMAL(10,2) NOT NULL,
    Lagerbestand INT NOT NULL DEFAULT 0,
    Aktiv BIT NOT NULL DEFAULT 1,
    EinheitMenge DECIMAL(10,3) NOT NULL DEFAULT 1,
    EinheitTyp NVARCHAR(20) NOT NULL DEFAULT N'kg',
    IstErnährungstrend BIT NOT NULL DEFAULT 0,
    IstAktiv BIT NOT NULL DEFAULT 1,
    CONSTRAINT CK_Produkt_Preis CHECK (Preis >= 0),
    CONSTRAINT CK_Produkt_Lagerbestand CHECK (Lagerbestand >= 0)
);

CREATE TABLE Bestellung (
    BestellungID INT IDENTITY(1,1) PRIMARY KEY,
    KundeID INT NOT NULL FOREIGN KEY REFERENCES Kunde(KundeID),
    Bestelldatum DATETIME NOT NULL DEFAULT GETDATE(),
    Status NVARCHAR(50) NOT NULL,
    Gesamtbetrag DECIMAL(10,2) NOT NULL DEFAULT 0
);

CREATE TABLE Bestellposition (
    BestellpositionID INT IDENTITY(1,1) PRIMARY KEY,
    BestellungID INT NOT NULL FOREIGN KEY REFERENCES Bestellung(BestellungID) ON DELETE CASCADE,
    ProduktID INT NOT NULL FOREIGN KEY REFERENCES Produkt(ProduktID),
    Menge INT NOT NULL,
    Einzelpreis DECIMAL(10,2) NOT NULL,
    CONSTRAINT CK_Bestellposition_Menge CHECK (Menge > 0),
    CONSTRAINT CK_Bestellposition_Einzelpreis CHECK (Einzelpreis >= 0)
);

CREATE TABLE Rechnung (
    RechnungID INT IDENTITY(1,1) PRIMARY KEY,
    BestellungID INT NOT NULL UNIQUE FOREIGN KEY REFERENCES Bestellung(BestellungID),
    Rechnungsnummer NVARCHAR(30) NOT NULL UNIQUE,
    Rechnungsdatum DATETIME NOT NULL DEFAULT GETDATE(),
    Betrag DECIMAL(10,2) NOT NULL
);

CREATE TABLE DSGVO_Anfrage (
    AnfrageID INT IDENTITY(1,1) PRIMARY KEY,
    KundeID INT NOT NULL FOREIGN KEY REFERENCES Kunde(KundeID),
    TypID INT NOT NULL FOREIGN KEY REFERENCES DSGVO_AnfrageTyp(TypID),
    Eingangsdatum DATETIME NOT NULL DEFAULT GETDATE(),
    StatusID INT NOT NULL FOREIGN KEY REFERENCES DSGVO_AnfrageStatus(StatusID),
    BearbeitetAm DATETIME NULL,
    BearbeitetVon NVARCHAR(100) NULL,
    Bemerkung NVARCHAR(500) NULL
);

CREATE TABLE AuditLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    KundeID INT NULL FOREIGN KEY REFERENCES Kunde(KundeID) ON DELETE SET NULL,
    Aktion NVARCHAR(100) NOT NULL,
    Zeitpunkt DATETIME NOT NULL DEFAULT GETDATE(),
    Benutzer NVARCHAR(100) NOT NULL,
    Details NVARCHAR(1000) NULL
);
GO

-- ============================================
-- Basisdaten einfügen
-- ============================================

INSERT INTO DatenschutzStatus (Name) VALUES (N'Aktiv'), (N'Geloescht'), (N'Anonymisiert');
INSERT INTO BestellungStatus (Name) VALUES (N'Offen'), (N'Bezahlt'), (N'Versendet'), (N'Storniert');
INSERT INTO DSGVO_AnfrageTyp (Name) VALUES (N'AUSKUNFT'), (N'LOESCHUNG');
INSERT INTO DSGVO_AnfrageStatus (Name) VALUES (N'Offen'), (N'Erledigt');
GO

-- ============================================
-- Beispieldaten einfügen
-- ============================================

INSERT INTO Kunde (Vorname, Nachname, EMail, Telefon, Adresse) VALUES
(N'Anna', N'Meyer', N'anna.meyer@example.de', N'040111111', N'Musterweg 1, 20095 Hamburg'),
(N'Lukas', N'Schmidt', N'lukas.schmidt@example.de', N'040222222', N'Hauptstr. 5, 20099 Hamburg'),
(N'Sophie', N'Becker', N'sophie.becker@example.de', N'040333333', N'Elballee 10, 22767 Hamburg'),
(N'Max', N'Fischer', N'max.fischer@example.de', NULL, N'Alsterufer 7, 20354 Hamburg'),
(N'Laura', N'Weber', N'laura.weber@example.de', N'040555555', N'Gartenweg 22, 22335 Hamburg');

INSERT INTO Produkt (Name, Kategorie, Preis, Lagerbestand) VALUES
(N'Tomate Bio', N'Einzelgemüse', 2.49, 100),
(N'Kartoffel regional', N'Einzelgemüse', 1.99, 200),
(N'Apfel Elstar', N'Einzelobst', 3.49, 150),
(N'Basilikum Topf', N'Kräuter & Gewürze', 2.99, 50),
(N'Karottensamen', N'Kräuter & Gewürze', 1.49, 80);

-- Erweiterte Produkte (aus Migration)
INSERT INTO Produkt (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp, IstErnährungstrend, IstAktiv, Lagerbestand) VALUES
(N'Bio-Box Classic', N'Gemischte saisonale Gemüse- und Obstselektion in Bio-Qualität.', N'Bio-Box', 24.90, 1, N'Box', 0, 1, 50),
(N'Gemüse-Box Standard', N'Saisonales Gemüse aus regionalem Bio-Anbau.', N'Gemüse-Box', 19.90, 1, N'Box', 0, 1, 35),
(N'Obst-Box Classic', N'Saisonale Obstauswahl in zertifizierter Bio-Qualität.', N'Obst-Box', 21.90, 1, N'Box', 0, 1, 45),
(N'Kräuter-Box Premium', N'Frische Küchenkräuter: Basilikum, Rosmarin, Thymian, Petersilie, Minze.', N'Kräuter-Box', 12.90, 1, N'Box', 0, 1, 60),
(N'Superfood-Box', N'Brokkoli, Spinat, Grünkohl, Chia-Samen – reich an Antioxidantien und Nährstoffen.', N'Superfood-Box', 29.90, 1, N'Box', 1, 1, 20),
(N'Rohkost-Box', N'Perfekt für die Rohkost-Ernährung: Karotten, Kohlrabi, Sellerie, Rote Bete.', N'Rohkost-Box', 22.50, 1, N'Box', 1, 1, 25),
(N'Saisonale Box Sommer', N'Tomaten, Zucchini, Paprika, Gurken – frisch aus der Sommersaison.', N'Saisonale Box', 20.90, 1, N'Box', 0, 1, 30),
(N'Saisonale Box Herbst', N'Kürbis, Sellerie, Pastinaken, Rote Bete – typisch für die Herbstsaison.', N'Saisonale Box', 20.90, 1, N'Box', 0, 1, 28),
(N'Bio-Möhren', N'Frische Bio-Karotten, lose, knackig und süß.', N'Einzelgemüse', 2.49, 1, N'kg', 0, 1, 110),
(N'Bio-Ingwer', N'Frischer Bio-Ingwer – Trend-Zutat für Tee, Smoothies und Küche.', N'Ernährungstrend', 1.99, 100, N'g', 1, 1, 75),
(N'Bio-Kurkuma', N'Frische Kurkumawurzel – entzündungshemmend und ein echter Trend.', N'Ernährungstrend', 2.49, 100, N'g', 1, 1, 70);

INSERT INTO Bestellung (KundeID, Bestelldatum, Status, Gesamtbetrag) VALUES
(1, '2026-05-01', N'Bezahlt', 45.80),
(2, '2026-05-10', N'Bezahlt', 85.40),
(3, '2026-05-20', N'Offen', 15.90);

INSERT INTO Bestellposition (BestellungID, ProduktID, Menge, Einzelpreis) VALUES
(1, 1, 10, 2.49),
(1, 3, 5, 3.49),
(2, 2, 20, 1.99),
(3, 4, 5, 2.99);

INSERT INTO Rechnung (BestellungID, Rechnungsnummer, Rechnungsdatum, Betrag) VALUES
(1, N'KR-2026-0001', '2026-05-01', 45.80),
(2, N'KR-2026-0002', '2026-05-10', 85.40);
GO

-- ============================================
-- View: DSGVO-Anfragen mit Namen
-- ============================================

CREATE VIEW v_DSGVO_Anfragen AS
SELECT
    a.AnfrageID,
    a.KundeID,
    k.Vorname,
    k.Nachname,
    t.Name AS Typ,
    a.Eingangsdatum,
    s.Name AS Status,
    a.BearbeitetAm,
    a.BearbeitetVon,
    a.Bemerkung
FROM DSGVO_Anfrage a
JOIN Kunde k ON a.KundeID = k.KundeID
JOIN DSGVO_AnfrageTyp t ON a.TypID = t.TypID
JOIN DSGVO_AnfrageStatus s ON a.StatusID = s.StatusID;
GO

-- ============================================
-- Stored Procedures
-- ============================================

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
    FROM Kunde WHERE KundeID = @KundeID;
    SELECT BestellungID, Bestelldatum, Status, Gesamtbetrag
    FROM Bestellung WHERE KundeID = @KundeID ORDER BY Bestelldatum;
    SELECT bp.BestellpositionID, bp.BestellungID, p.Name AS Produktname, bp.Menge, bp.Einzelpreis
    FROM Bestellposition bp JOIN Produkt p ON bp.ProduktID = p.ProduktID JOIN Bestellung b ON bp.BestellungID = b.BestellungID
    WHERE b.KundeID = @KundeID ORDER BY bp.BestellungID;
    SELECT r.RechnungID, r.BestellungID, r.Rechnungsnummer, r.Rechnungsdatum, r.Betrag
    FROM Rechnung r JOIN Bestellung b ON r.BestellungID = b.BestellungID WHERE b.KundeID = @KundeID ORDER BY r.Rechnungsdatum;
END;
GO

CREATE PROCEDURE sp_DSGVO_LoescheKunde
    @KundeID INT,
    @BearbeitetVon NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @HatRechnungen INT = (
        SELECT COUNT(*) FROM Rechnung r
        JOIN Bestellung b ON r.BestellungID = b.BestellungID
        WHERE b.KundeID = @KundeID
    );
    DECLARE @HatBestellungen INT = (
        SELECT COUNT(*) FROM Bestellung WHERE KundeID = @KundeID
    );
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
            Adresse = NULL,
            DatenschutzStatus = N'Anonymisiert',
            GeloeschtAm = GETDATE()
        WHERE KundeID = @KundeID;
        UPDATE DSGVO_Anfrage
        SET StatusID = (SELECT StatusID FROM DSGVO_AnfrageStatus WHERE Name = N'Erledigt'),
            BearbeitetAm = GETDATE(),
            BearbeitetVon = @BearbeitetVon
        WHERE KundeID = @KundeID AND TypID = (SELECT TypID FROM DSGVO_AnfrageTyp WHERE Name = N'LOESCHUNG');
        EXEC sp_AuditLogEintrag @KundeID, N'Kunde anonymisiert', @BearbeitetVon, N'Bestellungen/Rechnungen vorhanden';
    END
END;
GO

PRINT 'Datenbank "KrautUndRuebenDB" erfolgreich erstellt!';
GO

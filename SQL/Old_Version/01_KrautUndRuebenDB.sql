IF DB_ID('KrautUndRuebenDB') IS NULL
BEGIN
    CREATE DATABASE KrautUndRuebenDB;
END
GO

USE KrautUndRuebenDB;
GO

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

CREATE TABLE DatenschutzStatus (
    DatenschutzStatusID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(20) NOT NULL UNIQUE
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
    Erstellungsdatum DATETIME NOT NULL DEFAULT GETDATE(),
    DatenschutzStatusID INT NOT NULL DEFAULT 1,
    GeloeschtAm DATETIME NULL,
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

CREATE TABLE Kategorie (
    KategorieID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Produkt (
    ProduktID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(150) NOT NULL,
    KategorieID INT NOT NULL,
    Preis DECIMAL(10,2) NOT NULL,
    Lagerbestand INT NOT NULL DEFAULT 0,
    Aktiv BIT NOT NULL DEFAULT 1,
    CONSTRAINT CK_Produkt_Preis CHECK (Preis >= 0),
    CONSTRAINT CK_Produkt_Lagerbestand CHECK (Lagerbestand >= 0),
    CONSTRAINT FK_Produkt_Kategorie FOREIGN KEY (KategorieID) REFERENCES Kategorie(KategorieID)
);

CREATE TABLE Bestellung (
    BestellungID INT IDENTITY(1,1) PRIMARY KEY,
    KundeID INT NOT NULL,
    Bestelldatum DATETIME NOT NULL DEFAULT GETDATE(),
    BestellungStatusID INT NOT NULL,
    CONSTRAINT FK_Bestellung_Kunde FOREIGN KEY (KundeID) REFERENCES Kunde(KundeID),
    CONSTRAINT FK_Bestellung_Status FOREIGN KEY (BestellungStatusID) REFERENCES BestellungStatus(BestellungStatusID)
);

CREATE TABLE Bestellposition (
    BestellpositionID INT IDENTITY(1,1) PRIMARY KEY,
    BestellungID INT NOT NULL,
    ProduktID INT NOT NULL,
    Menge INT NOT NULL,
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
    Rechnungsdatum DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Rechnung_Bestellung FOREIGN KEY (BestellungID) REFERENCES Bestellung(BestellungID)
);

CREATE TABLE DSGVO_Anfrage (
    AnfrageID INT IDENTITY(1,1) PRIMARY KEY,
    KundeID INT NOT NULL,
    TypID INT NOT NULL,
    Eingangsdatum DATETIME NOT NULL DEFAULT GETDATE(),
    StatusID INT NOT NULL,
    BearbeitetAm DATETIME NULL,
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
    Zeitpunkt DATETIME NOT NULL DEFAULT GETDATE(),
    Benutzer NVARCHAR(100) NOT NULL,
    Details NVARCHAR(1000) NULL,
    CONSTRAINT FK_AuditLog_Kunde FOREIGN KEY (KundeID) REFERENCES Kunde(KundeID) ON DELETE SET NULL
);
GO

INSERT INTO DatenschutzStatus (Name) VALUES ('AKTIV'), ('GELOESCHT');
INSERT INTO BestellungStatus (Name) VALUES ('Offen'), ('Bezahlt'), ('Versendet'), ('Storniert');
INSERT INTO DSGVO_AnfrageTyp (Name) VALUES ('AUSKUNFT'), ('LOESCHUNG');
INSERT INTO DSGVO_AnfrageStatus (Name) VALUES ('OFFEN'), ('ERLEDIGT');

INSERT INTO Kategorie (Name) VALUES ('Gemuese'), ('Obst'), ('Kraeuter'), ('Saatgut');

INSERT INTO Produkt (Name, KategorieID, Preis, Lagerbestand, Aktiv) VALUES
('Tomate Bio', 1, 2.49, 100, 1),
('Kartoffel regional', 1, 1.99, 200, 1),
('Apfel Elstar', 2, 3.49, 150, 1),
('Basilikum Topf', 3, 2.99, 50, 1),
('Karottensamen', 4, 1.49, 80, 1),
('Zucchini', 1, 2.79, 120, 1);

INSERT INTO Kunde (Vorname, Nachname, EMail, Telefon) VALUES
('Anna', 'Meyer', 'anna.meyer@example.de', '040111111'),
('Lukas', 'Schmidt', 'lukas.schmidt@example.de', '040222222'),
('Sophie', 'Becker', 'sophie.becker@example.de', '040333333'),
('Max', 'Fischer', 'max.fischer@example.de', NULL),
('Laura', 'Weber', 'laura.weber@example.de', '040555555');

INSERT INTO KundenAdresse (KundeID, StrasseHausnummer, PLZ, Ort) VALUES
(1, 'Musterweg 1', '20095', 'Hamburg'),
(2, 'Hauptstr. 5', '20099', 'Hamburg'),
(3, 'Elballee 10', '22767', 'Hamburg'),
(4, 'Alsterufer 7', '20354', 'Hamburg'),
(5, 'Gartenweg 22', '22335', 'Hamburg');

DECLARE @StatusOffen INT = (SELECT BestellungStatusID FROM BestellungStatus WHERE Name = 'Offen');
DECLARE @StatusBezahlt INT = (SELECT BestellungStatusID FROM BestellungStatus WHERE Name = 'Bezahlt');
DECLARE @StatusVersendet INT = (SELECT BestellungStatusID FROM BestellungStatus WHERE Name = 'Versendet');

INSERT INTO Bestellung (KundeID, Bestelldatum, BestellungStatusID) VALUES
(1, '2026-05-01', @StatusBezahlt),
(1, '2026-05-15', @StatusVersendet),
(2, '2026-05-10', @StatusBezahlt),
(3, '2026-05-20', @StatusOffen);

INSERT INTO Bestellposition (BestellungID, ProduktID, Menge, Einzelpreis) VALUES
(1, 1, 2, 2.49), (1, 4, 1, 2.99), (1, 5, 3, 1.49),
(2, 2, 2, 1.99), (2, 6, 1, 2.79),
(3, 3, 2, 3.49), (3, 1, 1, 2.49), (3, 4, 2, 2.99),
(4, 2, 1, 1.99), (4, 4, 1, 2.99);

INSERT INTO Rechnung (BestellungID, Rechnungsnummer, Rechnungsdatum) VALUES
(1, 'KR-2026-0001', '2026-05-01'),
(2, 'KR-2026-0002', '2026-05-15'),
(3, 'KR-2026-0003', '2026-05-10');
GO

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
        CASE WHEN ka.StrasseHausnummer IS NOT NULL AND (ka.PLZ IS NOT NULL OR ka.Ort IS NOT NULL) THEN ', ' ELSE '' END,
        COALESCE(ka.PLZ, ''),
        CASE WHEN ka.PLZ IS NOT NULL AND ka.Ort IS NOT NULL THEN ' ' ELSE '' END,
        COALESCE(ka.Ort, '')
    ))), '') AS Adresse,
    k.Erstellungsdatum,
    ds.Name AS DatenschutzStatus,
    k.GeloeschtAm,
    CONCAT(k.Vorname, ' ', k.Nachname) AS Vollname
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
    DECLARE @StatusOffenID INT = (SELECT StatusID FROM DSGVO_AnfrageStatus WHERE Name = 'OFFEN');

    IF @TypID IS NULL
    BEGIN
        THROW 50001, 'Unbekannter DSGVO-Anfragetyp.', 1;
    END;

    INSERT INTO DSGVO_Anfrage (KundeID, TypID, StatusID, Bemerkung)
    VALUES (@KundeID, @TypID, @StatusOffenID, @Bemerkung);

    EXEC sp_AuditLogEintrag @KundeID, 'DSGVO-Anfrage angelegt', 'System', CONCAT('Typ: ', @Typ);
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
    DECLARE @StatusGeloeschtID INT = (SELECT DatenschutzStatusID FROM DatenschutzStatus WHERE Name = 'GELOESCHT');
    DECLARE @TypLoeschungID INT = (SELECT TypID FROM DSGVO_AnfrageTyp WHERE Name = 'LOESCHUNG');
    DECLARE @StatusOffenID INT = (SELECT StatusID FROM DSGVO_AnfrageStatus WHERE Name = 'OFFEN');
    DECLARE @StatusErledigtID INT = (SELECT StatusID FROM DSGVO_AnfrageStatus WHERE Name = 'ERLEDIGT');

    SELECT @HatRechnungen = COUNT(*)
    FROM Rechnung r
    INNER JOIN Bestellung b ON r.BestellungID = b.BestellungID
    WHERE b.KundeID = @KundeID;

    SELECT @HatBestellungen = COUNT(*)
    FROM Bestellung
    WHERE KundeID = @KundeID;

    IF @HatBestellungen = 0 AND @HatRechnungen = 0
    BEGIN
        EXEC sp_AuditLogEintrag @KundeID, 'Kunde physisch geloescht', @BearbeitetVon, 'Keine Bestellungen/Rechnungen vorhanden';

        DELETE FROM DSGVO_Anfrage WHERE KundeID = @KundeID;
        DELETE FROM Kunde WHERE KundeID = @KundeID;
    END
    ELSE
    BEGIN
        UPDATE Kunde
        SET Vorname = 'GELOESCHT',
            Nachname = 'GELOESCHT',
            EMail = CONCAT('deleted_', KundeID, '@example.local'),
            Telefon = NULL,
            DatenschutzStatusID = @StatusGeloeschtID,
            GeloeschtAm = GETDATE()
        WHERE KundeID = @KundeID;

        UPDATE KundenAdresse
        SET StrasseHausnummer = NULL,
            PLZ = NULL,
            Ort = NULL
        WHERE KundeID = @KundeID;

        UPDATE DSGVO_Anfrage
        SET StatusID = @StatusErledigtID, BearbeitetAm = GETDATE(), BearbeitetVon = @BearbeitetVon
        WHERE KundeID = @KundeID AND TypID = @TypLoeschungID AND StatusID = @StatusOffenID;

        EXEC sp_AuditLogEintrag @KundeID, 'Kunde anonymisiert', @BearbeitetVon, 'Bestellungen/Rechnungen vorhanden';
    END
END;
GO

-- Pflichtabfragen
SELECT b.BestellungID, b.Bestelldatum, b.Status, b.Gesamtbetrag, k.Vorname, k.Nachname
FROM v_BestellungMitGesamtbetrag b
INNER JOIN Kunde k ON b.KundeID = k.KundeID
ORDER BY b.BestellungID;

SELECT k.KundeID, k.Vorname, k.Nachname, b.BestellungID, b.Bestelldatum, b.Status
FROM Kunde k
LEFT JOIN v_BestellungMitGesamtbetrag b ON k.KundeID = b.KundeID
ORDER BY k.KundeID;

SELECT k.KundeID, k.Vorname, k.Nachname, b.BestellungID, b.Bestelldatum, b.Status
FROM Kunde k
RIGHT JOIN v_BestellungMitGesamtbetrag b ON k.KundeID = b.KundeID
ORDER BY b.BestellungID;

SELECT DISTINCT k.KundeID, k.Vorname, k.Nachname
FROM Kunde k
INNER JOIN v_BestellungMitGesamtbetrag b ON k.KundeID = b.KundeID
WHERE b.Gesamtbetrag > (SELECT AVG(Gesamtbetrag) FROM v_BestellungMitGesamtbetrag);

SELECT
    k.KundeID,
    k.Vorname,
    k.Nachname,
    COUNT(b.BestellungID) AS AnzahlBestellungen,
    ISNULL(SUM(b.Gesamtbetrag), 0) AS Gesamtumsatz,
    ISNULL(AVG(b.Gesamtbetrag), 0) AS DurchschnittsBestellwert
FROM Kunde k
LEFT JOIN v_BestellungMitGesamtbetrag b ON k.KundeID = b.KundeID
GROUP BY k.KundeID, k.Vorname, k.Nachname
ORDER BY Gesamtumsatz DESC;

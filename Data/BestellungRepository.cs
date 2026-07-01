using System.Data;
using System.Data.SqlClient;

namespace KrautUndRuebenApp.Data
{
    public class BestellungRepository
    {
        public DataTable GetBestellungenMitKunden() =>
            LoadTable(@"SELECT b.BestellungID, b.Bestelldatum, b.Status, b.Gesamtbetrag,
                               k.Vorname, k.Nachname
                        FROM Bestellung b
                        INNER JOIN Kunde k ON b.KundeID = k.KundeID
                        ORDER BY b.BestellungID");

        public DataTable GetBestellpositionen() =>
            LoadTable(@"SELECT bp.BestellpositionID, bp.BestellungID,
                               p.Name AS Produktname, bp.Menge, bp.Einzelpreis
                        FROM Bestellposition bp
                        INNER JOIN Produkt p ON bp.ProduktID = p.ProduktID
                        ORDER BY bp.BestellungID");

        public DataTable GetRechnungen() =>
            LoadTable(@"SELECT RechnungID, BestellungID, Rechnungsdatum, Betrag
                        FROM Rechnung
                        ORDER BY RechnungID");

        private DataTable LoadTable(string sql)
        {
            using SqlConnection conn = Database.GetConnection();
            conn.Open();
            using SqlDataAdapter adapter = new SqlDataAdapter(sql, conn);
            DataTable dt = new DataTable();
            adapter.Fill(dt);
            return dt;
        }
    }
}

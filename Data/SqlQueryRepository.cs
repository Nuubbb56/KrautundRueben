using System.Data;
using System.Data.SqlClient;

namespace KrautUndRuebenApp.Data
{
    public class SqlQueryRepository
    {
        public DataTable ExecuteQuery(string sql)
        {
            using SqlConnection conn = Database.GetConnection();
            conn.Open();
            using SqlDataAdapter adapter = new SqlDataAdapter(sql, conn);
            DataTable dt = new DataTable();
            adapter.Fill(dt);
            return dt;
        }

        public string GetInnerJoinQuery() => @"
            SELECT b.BestellungID, b.Bestelldatum, b.Status, b.Gesamtbetrag,
                   k.Vorname, k.Nachname
            FROM Bestellung b
            INNER JOIN Kunde k ON b.KundeID = k.KundeID
            ORDER BY b.BestellungID";

        public string GetLeftJoinQuery() => @"
            SELECT k.KundeID, k.Vorname, k.Nachname,
                   b.BestellungID, b.Bestelldatum, b.Status
            FROM Kunde k
            LEFT JOIN Bestellung b ON k.KundeID = b.KundeID
            ORDER BY k.KundeID";

        public string GetRightJoinQuery() => @"
            SELECT k.KundeID, k.Vorname, k.Nachname,
                   b.BestellungID, b.Bestelldatum, b.Status
            FROM Kunde k
            RIGHT JOIN Bestellung b ON k.KundeID = b.KundeID
            ORDER BY b.BestellungID";

        public string GetSubselectQuery() => @"
            SELECT DISTINCT k.KundeID, k.Vorname, k.Nachname
            FROM Kunde k
            INNER JOIN Bestellung b ON k.KundeID = b.KundeID
            WHERE b.Gesamtbetrag > (SELECT AVG(Gesamtbetrag) FROM Bestellung)";

        public string GetAggregatQuery() => @"
            SELECT k.KundeID, k.Vorname, k.Nachname,
                   COUNT(b.BestellungID)          AS AnzahlBestellungen,
                   ISNULL(SUM(b.Gesamtbetrag), 0) AS Gesamtumsatz,
                   ISNULL(AVG(b.Gesamtbetrag), 0) AS DurchschnittsBestellwert
            FROM Kunde k
            LEFT JOIN Bestellung b ON k.KundeID = b.KundeID
            GROUP BY k.KundeID, k.Vorname, k.Nachname
            ORDER BY Gesamtumsatz DESC";
    }
}

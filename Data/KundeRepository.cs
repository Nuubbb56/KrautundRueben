using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using KrautUndRuebenApp.Models;

namespace KrautUndRuebenApp.Data
{
    public class KundeRepository
    {
        public DataTable GetAllKunden()
        {
            const string sql = @"SELECT KundeID, Vorname, Nachname, EMail, Telefon, Adresse,
                                        DatenschutzStatus,
                                        CONCAT(Vorname, ' ', Nachname) AS Vollname
                                 FROM Kunde
                                 ORDER BY KundeID";
            return LoadTable(sql);
        }

        public DataTable SearchKunden(string suchtext)
        {
            using SqlConnection conn = Database.GetConnection();
            conn.Open();
            const string sql = @"SELECT KundeID, Vorname, Nachname, EMail, Telefon, Adresse,
                                        DatenschutzStatus,
                                        CONCAT(Vorname, ' ', Nachname) AS Vollname
                                 FROM Kunde
                                 WHERE Vorname LIKE @q OR Nachname LIKE @q OR EMail LIKE @q
                                 ORDER BY KundeID";
            using SqlCommand cmd = new SqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@q", "%" + suchtext + "%");
            using SqlDataAdapter adapter = new SqlDataAdapter(cmd);
            DataTable dt = new DataTable();
            adapter.Fill(dt);
            return dt;
        }

        public List<KundeItem> GetKundenListe()
        {
            List<KundeItem> kunden = new List<KundeItem>();
            DataTable dt = GetAllKunden();
            foreach (DataRow row in dt.Rows)
            {
                kunden.Add(new KundeItem
                {
                    KundeID  = Convert.ToInt32(row["KundeID"]),
                    Vollname = row["Vollname"].ToString()
                });
            }
            return kunden;
        }

        public void AddKunde(string vorname, string nachname, string email,
                               string telefon, string adresse)
        {
            using SqlConnection conn = Database.GetConnection();
            conn.Open();
            const string sql = @"INSERT INTO Kunde (Vorname, Nachname, EMail, Telefon, Adresse)
                                 VALUES (@Vorname, @Nachname, @EMail, @Telefon, @Adresse)";
            using SqlCommand cmd = new SqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@Vorname",  vorname);
            cmd.Parameters.AddWithValue("@Nachname", nachname);
            cmd.Parameters.AddWithValue("@EMail",    email);
            cmd.Parameters.AddWithValue("@Telefon",
                string.IsNullOrWhiteSpace(telefon) ? (object)DBNull.Value : telefon);
            cmd.Parameters.AddWithValue("@Adresse",
                string.IsNullOrWhiteSpace(adresse) ? (object)DBNull.Value : adresse);
            cmd.ExecuteNonQuery();
        }

        public void UpdateKunde(int kundeId, string vorname, string nachname, string email,
                                  string telefon, string adresse)
        {
            using SqlConnection conn = Database.GetConnection();
            conn.Open();
            const string sql = @"UPDATE Kunde
                                 SET Vorname  = @Vorname,
                                     Nachname = @Nachname,
                                     EMail    = @EMail,
                                     Telefon  = @Telefon,
                                     Adresse  = @Adresse
                                 WHERE KundeID = @KundeID";
            using SqlCommand cmd = new SqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@KundeID",  kundeId);
            cmd.Parameters.AddWithValue("@Vorname",  vorname);
            cmd.Parameters.AddWithValue("@Nachname", nachname);
            cmd.Parameters.AddWithValue("@EMail",    email);
            cmd.Parameters.AddWithValue("@Telefon",
                string.IsNullOrWhiteSpace(telefon) ? (object)DBNull.Value : telefon);
            cmd.Parameters.AddWithValue("@Adresse",
                string.IsNullOrWhiteSpace(adresse) ? (object)DBNull.Value : adresse);
            cmd.ExecuteNonQuery();
        }

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

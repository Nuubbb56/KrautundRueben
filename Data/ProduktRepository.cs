using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using KrautUndRuebenApp.Models;

namespace KrautUndRuebenApp.Data
{
    public class ProduktRepository
    {
        public DataTable GetAllProdukte()
        {
            const string sql = @"
                SELECT ProduktID, Name, Beschreibung, Kategorie, Preis,
                       EinheitMenge, EinheitTyp, IstErnährungstrend, IstAktiv
                FROM Produkt
                ORDER BY Kategorie, Name";
            return LoadTable(sql);
        }

        public DataTable GetProdukteByKategorie(string kategorie)
        {
            using SqlConnection conn = Database.GetConnection();
            conn.Open();
            const string sql = @"
                SELECT ProduktID, Name, Beschreibung, Kategorie, Preis,
                       EinheitMenge, EinheitTyp, IstErnährungstrend, IstAktiv
                FROM Produkt
                WHERE (@Kategorie = 'Alle' OR Kategorie = @Kategorie) AND IstAktiv = 1
                ORDER BY Name";
            using SqlCommand cmd = new SqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@Kategorie", kategorie);
            using SqlDataAdapter adapter = new SqlDataAdapter(cmd);
            DataTable dt = new DataTable();
            adapter.Fill(dt);
            return dt;
        }

        public DataTable GetErnährungstrends()
        {
            const string sql = @"
                SELECT ProduktID, Name, Beschreibung, Kategorie, Preis,
                       EinheitMenge, EinheitTyp, IstErnährungstrend, IstAktiv
                FROM Produkt
                WHERE IstErnährungstrend = 1 AND IstAktiv = 1
                ORDER BY Kategorie, Name";
            return LoadTable(sql);
        }

        public DataTable SearchProdukte(string suchtext)
        {
            using SqlConnection conn = Database.GetConnection();
            conn.Open();
            const string sql = @"
                SELECT ProduktID, Name, Beschreibung, Kategorie, Preis,
                       EinheitMenge, EinheitTyp, IstErnährungstrend, IstAktiv
                FROM Produkt
                WHERE Name LIKE @q OR Beschreibung LIKE @q OR Kategorie LIKE @q
                ORDER BY Kategorie, Name";
            using SqlCommand cmd = new SqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@q", "%" + suchtext + "%");
            using SqlDataAdapter adapter = new SqlDataAdapter(cmd);
            DataTable dt = new DataTable();
            adapter.Fill(dt);
            return dt;
        }

        public List<ProduktItem> GetProduktListe()
        {
            var list = new List<ProduktItem>();
            foreach (DataRow row in GetAllProdukte().Rows)
            {
                list.Add(new ProduktItem
                {
                    ProduktID = Convert.ToInt32(row["ProduktID"]),
                    Name      = row["Name"].ToString(),
                    Kategorie = row["Kategorie"].ToString()
                });
            }
            return list;
        }

        public void AddProdukt(string name, string beschreibung, string kategorie,
                               decimal preis, decimal einheitMenge, string einheitTyp,
                               bool istErnährungstrend)
        {
            using SqlConnection conn = Database.GetConnection();
            conn.Open();
            const string sql = @"
                INSERT INTO Produkt
                    (Name, Beschreibung, Kategorie, Preis, EinheitMenge, EinheitTyp,
                     IstErnährungstrend, IstAktiv)
                VALUES
                    (@Name, @Beschreibung, @Kategorie, @Preis, @EinheitMenge, @EinheitTyp,
                     @IstErnährungstrend, 1)";
            using SqlCommand cmd = new SqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@Name", name);
            cmd.Parameters.AddWithValue("@Beschreibung",
                string.IsNullOrWhiteSpace(beschreibung) ? (object)DBNull.Value : beschreibung);
            cmd.Parameters.AddWithValue("@Kategorie",          kategorie);
            cmd.Parameters.AddWithValue("@Preis",              preis);
            cmd.Parameters.AddWithValue("@EinheitMenge",       einheitMenge);
            cmd.Parameters.AddWithValue("@EinheitTyp",         einheitTyp);
            cmd.Parameters.AddWithValue("@IstErnährungstrend", istErnährungstrend ? 1 : 0);
            cmd.ExecuteNonQuery();
        }

        public void UpdateProdukt(int produktId, string name, string beschreibung,
                                  string kategorie, decimal preis, decimal einheitMenge,
                                  string einheitTyp, bool istErnährungstrend, bool istAktiv)
        {
            using SqlConnection conn = Database.GetConnection();
            conn.Open();
            const string sql = @"
                UPDATE Produkt
                SET Name               = @Name,
                    Beschreibung       = @Beschreibung,
                    Kategorie          = @Kategorie,
                    Preis              = @Preis,
                    EinheitMenge       = @EinheitMenge,
                    EinheitTyp         = @EinheitTyp,
                    IstErnährungstrend = @IstErnährungstrend,
                    IstAktiv           = @IstAktiv
                WHERE ProduktID = @ProduktID";
            using SqlCommand cmd = new SqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@ProduktID",          produktId);
            cmd.Parameters.AddWithValue("@Name",               name);
            cmd.Parameters.AddWithValue("@Beschreibung",
                string.IsNullOrWhiteSpace(beschreibung) ? (object)DBNull.Value : beschreibung);
            cmd.Parameters.AddWithValue("@Kategorie",          kategorie);
            cmd.Parameters.AddWithValue("@Preis",              preis);
            cmd.Parameters.AddWithValue("@EinheitMenge",       einheitMenge);
            cmd.Parameters.AddWithValue("@EinheitTyp",         einheitTyp);
            cmd.Parameters.AddWithValue("@IstErnährungstrend", istErnährungstrend ? 1 : 0);
            cmd.Parameters.AddWithValue("@IstAktiv",           istAktiv ? 1 : 0);
            cmd.ExecuteNonQuery();
        }

        public void DeactivateProdukt(int produktId)
        {
            using SqlConnection conn = Database.GetConnection();
            conn.Open();
            const string sql = "UPDATE Produkt SET IstAktiv = 0 WHERE ProduktID = @ProduktID";
            using SqlCommand cmd = new SqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@ProduktID", produktId);
            cmd.ExecuteNonQuery();
        }

        public List<string> GetKategorien()
        {
            var list = new List<string> { "Alle" };
            using SqlConnection conn = Database.GetConnection();
            conn.Open();
            const string sql = "SELECT DISTINCT Kategorie FROM Produkt ORDER BY Kategorie";
            using SqlCommand cmd = new SqlCommand(sql, conn);
            using SqlDataReader reader = cmd.ExecuteReader();
            while (reader.Read())
                list.Add(reader.GetString(0));
            return list;
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

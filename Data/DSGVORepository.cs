using System;
using System.Data;
using System.Data.SqlClient;
using System.Text;

namespace KrautUndRuebenApp.Data
{
    public class DSGVORepository
    {
        public void CreateRequest(int kundeId, string typ, string bemerkung)
        {
            using SqlConnection conn = Database.GetConnection();
            conn.Open();
            using SqlCommand cmd = new SqlCommand("sp_DSGVO_AnfrageAnlegen", conn);
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.AddWithValue("@KundeID", kundeId);
            cmd.Parameters.AddWithValue("@Typ",      typ);
            cmd.Parameters.AddWithValue("@Bemerkung",
                string.IsNullOrWhiteSpace(bemerkung) ? (object)DBNull.Value : bemerkung);
            cmd.ExecuteNonQuery();
        }

        public DataSet GetDsgvoAuskunft(int kundeId)
        {
            using SqlConnection conn = Database.GetConnection();
            conn.Open();
            using SqlCommand cmd = new SqlCommand("sp_DSGVO_Auskunft", conn);
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.AddWithValue("@KundeID", kundeId);
            using SqlDataAdapter adapter = new SqlDataAdapter(cmd);
            DataSet ds = new DataSet();
            adapter.Fill(ds);
            return ds;
        }

        public void DeleteOrAnonymizeCustomer(int kundeId, string bearbeitetVon)
        {
            using SqlConnection conn = Database.GetConnection();
            conn.Open();
            using SqlCommand cmd = new SqlCommand("sp_DSGVO_LoescheKunde", conn);
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.AddWithValue("@KundeID",       kundeId);
            cmd.Parameters.AddWithValue("@BearbeitetVon", bearbeitetVon);
            cmd.ExecuteNonQuery();
        }

        public DataTable GetAnfragen() =>
            LoadTable("SELECT * FROM v_DSGVO_Anfragen ORDER BY AnfrageID DESC");

        public DataTable GetAuditLog() =>
            LoadTable("SELECT * FROM AuditLog ORDER BY LogID DESC");

        public string BuildAuskunftText(DataSet ds)
        {
            StringBuilder sb = new StringBuilder();
            sb.AppendLine("DSGVO-Auskunft");
            sb.AppendLine("======================================");

            if (ds.Tables.Count > 0 && ds.Tables[0].Rows.Count > 0)
            {
                DataRow k = ds.Tables[0].Rows[0];
                sb.AppendLine("Kundendaten:");
                foreach (DataColumn col in ds.Tables[0].Columns)
                    sb.AppendLine(col.ColumnName + ": " + Convert.ToString(k[col]));
                sb.AppendLine();
            }

            AppendTable(sb, "Bestellungen",      ds, 1);
            AppendTable(sb, "Bestellpositionen", ds, 2);
            AppendTable(sb, "Rechnungen",        ds, 3);
            return sb.ToString();
        }

        private void AppendTable(StringBuilder sb, string title, DataSet ds, int index)
        {
            sb.AppendLine(title + ":");
            if (ds.Tables.Count <= index || ds.Tables[index].Rows.Count == 0)
            {
                sb.AppendLine("Keine Daten vorhanden.");
                sb.AppendLine();
                return;
            }
            foreach (DataRow row in ds.Tables[index].Rows)
            {
                foreach (DataColumn col in ds.Tables[index].Columns)
                    sb.Append(col.ColumnName + "=" + Convert.ToString(row[col]) + " | ");
                sb.AppendLine();
            }
            sb.AppendLine();
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

using System.Data.SqlClient;

namespace KrautUndRuebenApp.Data
{
    public static class Database
    {
        // Bei SQL Server Express z. B. anpassen auf .\SQLEXPRESS
        private static readonly string connectionString =
            @"Server=(localdb)\MSSQLLocalDB;Database=KrautUndRuebenDB;Trusted_Connection=True;";

        public static SqlConnection GetConnection() => new SqlConnection(connectionString);
    }
}

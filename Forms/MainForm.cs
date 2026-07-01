using System.Drawing;
using System.Windows.Forms;

namespace KrautUndRuebenApp.Forms
{
    public class MainForm : Form
    {
        public MainForm()
        {
            Text = "Kraut & Rüben - Projektübersicht";
            Width = 760;
            Height = 540;
            StartPosition = FormStartPosition.CenterScreen;

            // Top = 25 statt 20, etwas mehr Abstand zum Titelbalken
            Label title = new Label
            {
                Text = "Kraut & Rüben – Warenwirtschaft + DSGVO",
                Left = 20,
                Top = 25,
                Width = 690,
                Height = 30,
                Font = new Font("Segoe UI", 14, FontStyle.Bold)
            };

            Label info = new Label
            {
                Left = 20,
                Top = 70,
                Width = 690,
                Height = 105,
                Text = "Dieses Projekt demonstriert:\n" +
                       "- Kundenverwaltung\n" +
                       "- Bestellungen und Rechnungen\n" +
                       "- Pflichtabfragen mit INNER/LEFT/RIGHT JOIN, Subselect und Aggregatfunktion\n" +
                       "- DSGVO-Auskunft und Löschung/Anonymisierung\n" +
                       "- Produktverwaltung mit erweitertem Sortiment & Ernährungstrends"
            };

            Button btnKunden = new Button { Text = "1. Kundenverwaltung", Left = 60, Top = 195, Width = 260, Height = 45 };
            Button btnBestellungen = new Button { Text = "2. Bestellungen / Rechnungen", Left = 390, Top = 195, Width = 260, Height = 45 };
            Button btnSql = new Button { Text = "3. SQL-Abfragen", Left = 60, Top = 260, Width = 260, Height = 45 };
            Button btnDsgvo = new Button { Text = "4. DSGVO-Modul", Left = 390, Top = 260, Width = 260, Height = 45 };

            Button btnProdukte = new Button
            {
                Text = "5. Produktverwaltung & Sortiment",
                Left = 60, Top = 325,
                Width = 590, Height = 45,
                BackColor = Color.DarkOliveGreen,
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Segoe UI", 10, FontStyle.Bold)
            };

            Label demo = new Label
            {
                Left = 20,
                Top = 390,
                Width = 700,
                Height = 80,
                Text = "Vorführungsreihenfolge: Kundenverwaltung → Bestellungen → SQL-Abfragen → DSGVO → Produkte.\n" +
                       "Im Ordner Doku/ liegt zusätzlich ein 5-Minuten-Vorführungsablauf.\n" +
                       "Neu: Sortiment inkl. Bio-Box, Superfood-Box, Rohkost-Box, Saisonale Box u. v. m."
            };

            btnKunden.Click += (s, e) => new KundenForm().ShowDialog();
            btnBestellungen.Click += (s, e) => new BestellungenForm().ShowDialog();
            btnSql.Click += (s, e) => new SqlAbfragenForm().ShowDialog();
            btnDsgvo.Click += (s, e) => new DsgvoForm().ShowDialog();
            btnProdukte.Click += (s, e) => new ProdukteForm().ShowDialog();

            Controls.AddRange(new Control[]
            {
                title, info,
                btnKunden, btnBestellungen,
                btnSql, btnDsgvo,
                btnProdukte,
                demo
            });
        }
    }
}

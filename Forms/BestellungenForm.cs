using System;
using System.Windows.Forms;
using KrautUndRuebenApp.Data;
using KrautUndRuebenApp.Utils;

namespace KrautUndRuebenApp.Forms
{
    public class BestellungenForm : Form
    {
        public BestellungenForm()
        {
            Text = "Bestellungen und Rechnungen";
            Width = 1050; Height = 680;
            StartPosition = FormStartPosition.CenterScreen;

            // Top = 20 statt 10, damit der Hinweistext nicht am Fensterrand klebt
            Label lbl = new Label
            {
                Text = "Demo-Hinweis: Hier sieht man Bestellungen, Bestellpositionen und Rechnungen.",
                Left = 20, Top = 20, Width = 900, Height = 22
            };
            Controls.Add(lbl);

            try
            {
                var repo = new BestellungRepository();
                var tabs = new TabControl { Left = 20, Top = 50, Width = 990, Height = 580 };

                var dgv1 = CreateGrid(repo.GetBestellungenMitKunden());
                var dgv2 = CreateGrid(repo.GetBestellpositionen());
                var dgv3 = CreateGrid(repo.GetRechnungen());

                var t1 = new TabPage("Bestellungen");      t1.Controls.Add(dgv1);
                var t2 = new TabPage("Bestellpositionen"); t2.Controls.Add(dgv2);
                var t3 = new TabPage("Rechnungen");        t3.Controls.Add(dgv3);

                tabs.TabPages.Add(t1); tabs.TabPages.Add(t2); tabs.TabPages.Add(t3);
                Controls.Add(tabs);
            }
            catch (Exception ex) { UiHelper.ShowError(ex); }
        }

        private DataGridView CreateGrid(object source) => new DataGridView
        {
            Dock = DockStyle.Fill,
            ReadOnly = true,
            AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
            DataSource = source
        };
    }
}

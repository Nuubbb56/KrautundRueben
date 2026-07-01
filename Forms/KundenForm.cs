using System;
using System.Windows.Forms;
using KrautUndRuebenApp.Data;
using KrautUndRuebenApp.Utils;

namespace KrautUndRuebenApp.Forms
{
    public class KundenForm : Form
    {
        private readonly KundeRepository _repo = new KundeRepository();
        private DataGridView dgv = new DataGridView();
        private TextBox txtSuche = new TextBox();
        private TextBox txtVorname = new TextBox();
        private TextBox txtNachname = new TextBox();
        private TextBox txtEmail = new TextBox();
        private TextBox txtTelefon = new TextBox();
        private TextBox txtAdresse = new TextBox();

        public KundenForm()
        {
            Text = "Kundenverwaltung";
            Width = 1080; Height = 690;
            StartPosition = FormStartPosition.CenterScreen;

            // Top = 20 statt 10, damit der Hinweistext nicht abgeschnitten wirkt
            Controls.Add(new Label
            {
                Text = "Demo-Hinweis: Hier kann ein Kunde gesucht, angelegt und bearbeitet werden.",
                Left = 20, Top = 20, Width = 900, Height = 22
            });

            Controls.Add(new Label { Text = "Suche:", Left = 20, Top = 52, Width = 60 });
            txtSuche.SetBounds(80, 48, 220, 25);
            Button btnSuche = new Button { Text = "Suchen", Left = 320, Top = 47, Width = 100 };
            Button btnReset = new Button { Text = "Alle anzeigen", Left = 430, Top = 47, Width = 120 };
            btnSuche.Click += (s, e) => Suche();
            btnReset.Click += (s, e) => LoadKunden();
            Controls.Add(txtSuche); Controls.Add(btnSuche); Controls.Add(btnReset);

            dgv.Left = 20; dgv.Top = 85; dgv.Width = 1020; dgv.Height = 300;
            dgv.ReadOnly = true;
            dgv.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
            dgv.MultiSelect = false;
            dgv.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
            dgv.CellClick += Dgv_CellClick;
            Controls.Add(dgv);

            int l = 20, b = 120, t = 410, g = 35;
            Controls.Add(new Label { Text = "Vorname:", Left = l, Top = t, Width = 100 }); txtVorname.SetBounds(b, t, 250, 25);
            Controls.Add(new Label { Text = "Nachname:", Left = l, Top = t + g, Width = 100 }); txtNachname.SetBounds(b, t + g, 250, 25);
            Controls.Add(new Label { Text = "E-Mail:", Left = l, Top = t + 2 * g, Width = 100 }); txtEmail.SetBounds(b, t + 2 * g, 250, 25);
            Controls.Add(new Label { Text = "Telefon:", Left = l, Top = t + 3 * g, Width = 100 }); txtTelefon.SetBounds(b, t + 3 * g, 250, 25);
            Controls.Add(new Label { Text = "Adresse:", Left = l, Top = t + 4 * g, Width = 100 }); txtAdresse.SetBounds(b, t + 4 * g, 400, 25);

            Button btnNeu = new Button { Text = "Neuen Kunden anlegen", Left = 600, Top = t, Width = 220, Height = 40 };
            Button btnUpd = new Button { Text = "Kunden aktualisieren", Left = 600, Top = t + 60, Width = 220, Height = 40 };
            Button btnLeeren = new Button { Text = "Eingabefelder leeren", Left = 600, Top = t + 120, Width = 220, Height = 40 };

            btnNeu.Click += BtnNeu_Click;
            btnUpd.Click += BtnUpd_Click;
            btnLeeren.Click += (s, e) => ClearInputs();

            Controls.AddRange(new Control[] { txtVorname, txtNachname, txtEmail, txtTelefon, txtAdresse, btnNeu, btnUpd, btnLeeren });
            LoadKunden();
        }

        private void LoadKunden() { try { dgv.DataSource = _repo.GetAllKunden(); } catch (Exception ex) { UiHelper.ShowError(ex); } }
        private void Suche() { try { dgv.DataSource = string.IsNullOrWhiteSpace(txtSuche.Text) ? _repo.GetAllKunden() : _repo.SearchKunden(txtSuche.Text.Trim()); } catch (Exception ex) { UiHelper.ShowError(ex); } }

        private void BtnNeu_Click(object sender, EventArgs e)
        {
            try
            {
                if (!ValidateInput()) return;
                _repo.AddKunde(txtVorname.Text.Trim(), txtNachname.Text.Trim(), txtEmail.Text.Trim(), txtTelefon.Text.Trim(), txtAdresse.Text.Trim());
                LoadKunden(); UiHelper.ShowInfo("Kunde wurde angelegt."); ClearInputs();
            }
            catch (Exception ex) { UiHelper.ShowError(ex); }
        }

        private void BtnUpd_Click(object sender, EventArgs e)
        {
            try
            {
                if (dgv.SelectedRows.Count == 0) { UiHelper.ShowInfo("Bitte zuerst einen Kunden auswählen."); return; }
                if (!ValidateInput()) return;
                int id = Convert.ToInt32(dgv.SelectedRows[0].Cells["KundeID"].Value);
                _repo.UpdateKunde(id, txtVorname.Text.Trim(), txtNachname.Text.Trim(), txtEmail.Text.Trim(), txtTelefon.Text.Trim(), txtAdresse.Text.Trim());
                LoadKunden(); UiHelper.ShowInfo("Kunde wurde aktualisiert.");
            }
            catch (Exception ex) { UiHelper.ShowError(ex); }
        }

        private bool ValidateInput()
        {
            if (string.IsNullOrWhiteSpace(txtVorname.Text) || string.IsNullOrWhiteSpace(txtNachname.Text) || string.IsNullOrWhiteSpace(txtEmail.Text))
            { UiHelper.ShowInfo("Vorname, Nachname und E-Mail sind Pflichtfelder."); return false; }
            return true;
        }

        private void ClearInputs() { txtVorname.Clear(); txtNachname.Clear(); txtEmail.Clear(); txtTelefon.Clear(); txtAdresse.Clear(); }

        private void Dgv_CellClick(object sender, DataGridViewCellEventArgs e)
        {
            if (e.RowIndex < 0) return;
            var row = dgv.Rows[e.RowIndex];
            txtVorname.Text = row.Cells["Vorname"].Value?.ToString();
            txtNachname.Text = row.Cells["Nachname"].Value?.ToString();
            txtEmail.Text = row.Cells["EMail"].Value?.ToString();
            txtTelefon.Text = row.Cells["Telefon"].Value?.ToString();
            txtAdresse.Text = row.Cells["Adresse"].Value?.ToString();
        }
    }
}

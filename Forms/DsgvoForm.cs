using System;
using System.Data;
using System.IO;
using System.Windows.Forms;
using KrautUndRuebenApp.Data;
using KrautUndRuebenApp.Utils;

namespace KrautUndRuebenApp.Forms
{
    public class DsgvoForm : Form
    {
        private readonly KundeRepository _kundeRepository = new KundeRepository();
        private readonly DSGVORepository _dsgvoRepository = new DSGVORepository();

        private ComboBox cmbKunden = new ComboBox();
        private TextBox txtBemerkung = new TextBox();
        private TextBox txtBearbeiter = new TextBox();

        private DataGridView dgvKundendaten = new DataGridView();
        private DataGridView dgvBestellungen = new DataGridView();
        private DataGridView dgvPositionen = new DataGridView();
        private DataGridView dgvRechnungen = new DataGridView();
        private DataGridView dgvAnfragen = new DataGridView();
        private DataGridView dgvAudit = new DataGridView();

        private DataSet lastAuskunft;

        public DsgvoForm()
        {
            Text = "DSGVO-Verwaltung";
            Width = 1320; Height = 810;
            StartPosition = FormStartPosition.CenterScreen;

            // Top = 20 statt 10, damit der Hinweistext nicht abgeschnitten wirkt
            Controls.Add(new Label
            {
                Text = "Demo-Hinweis: DSGVO-Auskunft (Art. 15) und Löschung/Anonymisierung (Art. 17).",
                Left = 20, Top = 20, Width = 900, Height = 22
            });

            Controls.Add(new Label { Text = "Kunde:", Left = 20, Top = 52, Width = 60 });
            cmbKunden.SetBounds(90, 48, 300, 25);
            cmbKunden.DropDownStyle = ComboBoxStyle.DropDownList;
            Controls.Add(cmbKunden);

            Controls.Add(new Label { Text = "Bearbeiter:", Left = 420, Top = 52, Width = 80 });
            txtBearbeiter.SetBounds(510, 48, 180, 25);
            txtBearbeiter.Text = "Sachbearbeiter1";
            Controls.Add(txtBearbeiter);

            Controls.Add(new Label { Text = "Bemerkung:", Left = 710, Top = 52, Width = 90 });
            txtBemerkung.SetBounds(800, 48, 250, 25);
            Controls.Add(txtBemerkung);

            Button b1 = new Button { Text = "Auskunftsantrag anlegen", Left = 20, Top = 88, Width = 200, Height = 35 };
            Button b2 = new Button { Text = "Löschantrag anlegen", Left = 230, Top = 88, Width = 200, Height = 35 };
            Button b3 = new Button { Text = "Auskunft laden", Left = 440, Top = 88, Width = 160, Height = 35 };
            Button b4 = new Button { Text = "Löschung durchführen", Left = 610, Top = 88, Width = 200, Height = 35 };
            Button b5 = new Button { Text = "Auskunft als TXT exportieren", Left = 820, Top = 88, Width = 240, Height = 35 };
            Button b6 = new Button { Text = "Rechtliche Grundlage", Left = 1070, Top = 88, Width = 200, Height = 35 };

            b1.Click += BtnAuskunftsantrag_Click;
            b2.Click += BtnLoeschantrag_Click;
            b3.Click += BtnAuskunftLaden_Click;
            b4.Click += BtnLoeschung_Click;
            b5.Click += BtnExport_Click;
            b6.Click += (s, e) => UiHelper.ShowInfo(
                "Art. 15 DSGVO: Recht auf Auskunft\n" +
                "Art. 17 DSGVO: Recht auf Löschung\n\n" +
                "Aber: Wenn gesetzliche Aufbewahrungspflichten bestehen (z. B. Rechnungen), " +
                "dürfen Daten oft nicht vollständig gelöscht werden. Dann wird anonymisiert.");

            Controls.AddRange(new Control[] { b1, b2, b3, b4, b5, b6 });

            var tabs = new TabControl { Left = 20, Top = 130, Width = 1260, Height = 620 };
            tabs.TabPages.Add(MakePage("Kundendaten", dgvKundendaten));
            tabs.TabPages.Add(MakePage("Bestellungen", dgvBestellungen));
            tabs.TabPages.Add(MakePage("Bestellpositionen", dgvPositionen));
            tabs.TabPages.Add(MakePage("Rechnungen", dgvRechnungen));
            tabs.TabPages.Add(MakePage("Anfragen", dgvAnfragen));
            tabs.TabPages.Add(MakePage("Audit-Log", dgvAudit));
            Controls.Add(tabs);

            LoadKunden();
            LoadLogs();
        }

        private TabPage MakePage(string title, DataGridView dgv)
        {
            dgv.Dock = DockStyle.Fill;
            dgv.ReadOnly = true;
            dgv.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
            var page = new TabPage(title);
            page.Controls.Add(dgv);
            return page;
        }

        private void LoadKunden()
        {
            try
            {
                cmbKunden.DataSource = _kundeRepository.GetKundenListe();
                cmbKunden.DisplayMember = "Vollname";
                cmbKunden.ValueMember = "KundeID";
            }
            catch (Exception ex) { UiHelper.ShowError(ex); }
        }

        private void LoadLogs()
        {
            try
            {
                dgvAnfragen.DataSource = _dsgvoRepository.GetAnfragen();
                dgvAudit.DataSource = _dsgvoRepository.GetAuditLog();
            }
            catch (Exception ex) { UiHelper.ShowError(ex); }
        }

        private int GetSelectedKundeId() => Convert.ToInt32(cmbKunden.SelectedValue);
        private string GetBearbeiter() => string.IsNullOrWhiteSpace(txtBearbeiter.Text) ? "Sachbearbeiter1" : txtBearbeiter.Text.Trim();

        private void BtnAuskunftsantrag_Click(object sender, EventArgs e)
        {
            try { _dsgvoRepository.CreateRequest(GetSelectedKundeId(), "AUSKUNFT", txtBemerkung.Text); LoadLogs(); UiHelper.ShowInfo("Auskunftsantrag wurde angelegt."); }
            catch (Exception ex) { UiHelper.ShowError(ex); }
        }

        private void BtnLoeschantrag_Click(object sender, EventArgs e)
        {
            try { _dsgvoRepository.CreateRequest(GetSelectedKundeId(), "LOESCHUNG", txtBemerkung.Text); LoadLogs(); UiHelper.ShowInfo("Löschantrag wurde angelegt."); }
            catch (Exception ex) { UiHelper.ShowError(ex); }
        }

        private void BtnAuskunftLaden_Click(object sender, EventArgs e)
        {
            try
            {
                lastAuskunft = _dsgvoRepository.GetDsgvoAuskunft(GetSelectedKundeId());
                if (lastAuskunft.Tables.Count > 0) dgvKundendaten.DataSource = lastAuskunft.Tables[0];
                if (lastAuskunft.Tables.Count > 1) dgvBestellungen.DataSource = lastAuskunft.Tables[1];
                if (lastAuskunft.Tables.Count > 2) dgvPositionen.DataSource = lastAuskunft.Tables[2];
                if (lastAuskunft.Tables.Count > 3) dgvRechnungen.DataSource = lastAuskunft.Tables[3];
                UiHelper.ShowInfo("DSGVO-Auskunft wurde geladen.");
            }
            catch (Exception ex) { UiHelper.ShowError(ex); }
        }

        private void BtnLoeschung_Click(object sender, EventArgs e)
        {
            try
            {
                if (!UiHelper.Confirm("Soll die Löschung/Anonymisierung wirklich durchgeführt werden?")) return;
                _dsgvoRepository.DeleteOrAnonymizeCustomer(GetSelectedKundeId(), GetBearbeiter());
                LoadKunden(); LoadLogs();
                UiHelper.ShowInfo("Löschung/Anonymisierung wurde durchgeführt.");
            }
            catch (Exception ex) { UiHelper.ShowError(ex); }
        }

        private void BtnExport_Click(object sender, EventArgs e)
        {
            try
            {
                if (lastAuskunft == null) { UiHelper.ShowInfo("Bitte zuerst eine DSGVO-Auskunft laden."); return; }
                using SaveFileDialog dialog = new SaveFileDialog();
                dialog.Filter = "Textdatei|*.txt";
                dialog.FileName = "DSGVO_Auskunft_Kunde_" + GetSelectedKundeId() + ".txt";
                if (dialog.ShowDialog() == DialogResult.OK)
                {
                    File.WriteAllText(dialog.FileName, _dsgvoRepository.BuildAuskunftText(lastAuskunft));
                    UiHelper.ShowInfo("Auskunft exportiert: " + dialog.FileName);
                }
            }
            catch (Exception ex) { UiHelper.ShowError(ex); }
        }
    }
}

using System;
using System.Collections.Generic;
using System.Drawing;
using System.Windows.Forms;
using KrautUndRuebenApp.Data;
using KrautUndRuebenApp.Utils;

namespace KrautUndRuebenApp.Forms
{
    public class ProdukteForm : Form
    {
        private readonly ProduktRepository _repo = new ProduktRepository();

        // Filter-Bereich
        private TextBox txtSuche = new TextBox();
        private ComboBox cmbKategorie = new ComboBox();
        private CheckBox chkNurTrends = new CheckBox();

        // Tabelle
        private DataGridView dgv = new DataGridView();

        // Eingabefelder
        private TextBox txtName = new TextBox();
        private TextBox txtBeschreibung = new TextBox();
        private ComboBox cmbKategorieEingabe = new ComboBox();
        private TextBox txtPreis = new TextBox();
        private TextBox txtEinheitMenge = new TextBox();
        private ComboBox cmbEinheitTyp = new ComboBox();
        private CheckBox chkIstTrend = new CheckBox();
        private CheckBox chkIstAktiv = new CheckBox();

        // Verfügbare Kategorien
        private readonly string[] _kategorien = new[]
        {
            "Bio-Box", "Gemüse-Box", "Obst-Box", "Kräuter-Box",
            "Superfood-Box", "Rohkost-Box", "Saisonale Box",
            "Einzelgemüse", "Einzelobst", "Kräuter & Gewürze",
            "Ernährungstrend"
        };

        private readonly string[] _einheitTypen = new[]
        {
            "kg", "g", "Stück", "Bund", "Box", "Glas", "Beutel", "Liter", "ml"
        };

        public ProdukteForm()
        {
            Text = "Produktverwaltung - Sortiment & Ernährungstrends";
            Width = 1150; Height = 870;
            StartPosition = FormStartPosition.CenterScreen;

            // ── Hinweis-Label ─────────────────────────────────────────────
            // Top = 35 statt 10, damit der Text nicht unter dem Titelbalken verschwindet
            Controls.Add(new Label
            {
                Text = "Verwalten Sie das gesamte Sortiment: Boxen, Einzelprodukte und aktuelle Ernährungstrends.",
                Left = 20, Top = 35, Width = 1000, Height = 22,
                Font = new Font("Segoe UI", 9, FontStyle.Italic)
            });

            // ── Filter-Leiste ─────────────────────────────────────────────
            Controls.Add(new Label { Text = "Suche:", Left = 20, Top = 68, Width = 50, Height = 20 });
            txtSuche.SetBounds(72, 64, 200, 25);
            Controls.Add(txtSuche);

            Controls.Add(new Label { Text = "Kategorie:", Left = 290, Top = 68, Width = 75, Height = 20 });
            cmbKategorie.SetBounds(368, 64, 180, 25);
            cmbKategorie.DropDownStyle = ComboBoxStyle.DropDownList;
            Controls.Add(cmbKategorie);

            chkNurTrends.Text = "Nur Ernährungstrends";
            chkNurTrends.SetBounds(565, 66, 190, 22);
            chkNurTrends.CheckedChanged += (s, e) => ApplyFilter();
            Controls.Add(chkNurTrends);

            Button btnSuche = new Button { Text = "Suchen", Left = 770, Top = 63, Width = 100, Height = 26 };
            Button btnAlle = new Button { Text = "Alle anzeigen", Left = 880, Top = 63, Width = 120, Height = 26 };
            btnSuche.Click += (s, e) => ApplyFilter();
            btnAlle.Click += (s, e) => LoadAlleProdukte();
            Controls.Add(btnSuche);
            Controls.Add(btnAlle);

            // ── DataGridView ──────────────────────────────────────────────
            dgv.SetBounds(20, 100, 1090, 290);
            dgv.ReadOnly = true;
            dgv.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
            dgv.MultiSelect = false;
            dgv.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
            dgv.CellClick += Dgv_CellClick;
            Controls.Add(dgv);

            // ── Trennlinie ────────────────────────────────────────────────
            var sep = new Panel { Left = 20, Top = 398, Width = 1090, Height = 2, BackColor = Color.LightGray };
            Controls.Add(sep);

            // ── Eingabebereich ────────────────────────────────────────────
            Controls.Add(new Label
            {
                Text = "Produkt anlegen / bearbeiten",
                Left = 20, Top = 408, Width = 400, Height = 22,
                Font = new Font("Segoe UI", 10, FontStyle.Bold)
            });

            int lx = 20, lw = 130, fx = 155, fw = 270, top = 437, gap = 36;

            // Zeile 1: Name
            Controls.Add(new Label { Text = "Produktname:*", Left = lx, Top = top, Width = lw, Height = 20 });
            txtName.SetBounds(fx, top, fw, 25);
            Controls.Add(txtName);

            // Zeile 2: Kategorie
            Controls.Add(new Label { Text = "Kategorie:*", Left = lx, Top = top + gap, Width = lw, Height = 20 });
            cmbKategorieEingabe.SetBounds(fx, top + gap, fw, 25);
            cmbKategorieEingabe.DropDownStyle = ComboBoxStyle.DropDownList;
            cmbKategorieEingabe.Items.AddRange(_kategorien);
            cmbKategorieEingabe.SelectedIndex = 0;
            Controls.Add(cmbKategorieEingabe);

            // Zeile 3: Preis
            Controls.Add(new Label { Text = "Preis (EUR):*", Left = lx, Top = top + 2 * gap, Width = lw, Height = 20 });
            txtPreis.SetBounds(fx, top + 2 * gap, 100, 25);
            Controls.Add(txtPreis);

            // Zeile 4: Einheit
            Controls.Add(new Label { Text = "Menge / Einheit:", Left = lx, Top = top + 3 * gap, Width = lw, Height = 20 });
            txtEinheitMenge.SetBounds(fx, top + 3 * gap, 80, 25);
            txtEinheitMenge.Text = "1";
            Controls.Add(txtEinheitMenge);
            cmbEinheitTyp.SetBounds(fx + 88, top + 3 * gap, 120, 25);
            cmbEinheitTyp.DropDownStyle = ComboBoxStyle.DropDownList;
            cmbEinheitTyp.Items.AddRange(_einheitTypen);
            cmbEinheitTyp.SelectedIndex = 0;
            Controls.Add(cmbEinheitTyp);

            // Beschreibung (rechte Spalte)
            int rx = 510, rw = 480;
            Controls.Add(new Label { Text = "Beschreibung:", Left = rx, Top = top, Width = 110, Height = 20 });
            txtBeschreibung.SetBounds(rx + 115, top, rw, 95);
            txtBeschreibung.Multiline = true;
            txtBeschreibung.ScrollBars = ScrollBars.Vertical;
            Controls.Add(txtBeschreibung);

            // Checkboxen
            chkIstTrend.Text = "Ist Ernährungstrend";
            chkIstTrend.SetBounds(fx, top + 4 * gap, 210, 22);
            Controls.Add(chkIstTrend);

            chkIstAktiv.Text = "Produkt aktiv";
            chkIstAktiv.SetBounds(fx + 220, top + 4 * gap, 150, 22);
            chkIstAktiv.Checked = true;
            Controls.Add(chkIstAktiv);

            // Aktions-Buttons
            int btnTop = top + 5 * gap + 12;
            Button btnNeu = new Button { Text = "Neu anlegen", Left = lx, Top = btnTop, Width = 155, Height = 38 };
            Button btnUpdate = new Button { Text = "Aktualisieren", Left = lx + 165, Top = btnTop, Width = 155, Height = 38 };
            Button btnDeaktiv = new Button { Text = "Deaktivieren", Left = lx + 330, Top = btnTop, Width = 155, Height = 38 };
            Button btnLeeren = new Button { Text = "Felder leeren", Left = lx + 495, Top = btnTop, Width = 155, Height = 38 };
            Button btnTrends = new Button
            {
                Text = "Ernährungstrends anzeigen",
                Left = lx + 680, Top = btnTop, Width = 220, Height = 38,
                BackColor = Color.DarkOliveGreen, ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };

            btnNeu.Click += BtnNeu_Click;
            btnUpdate.Click += BtnUpdate_Click;
            btnDeaktiv.Click += BtnDeaktiv_Click;
            btnLeeren.Click += (s, e) => ClearInputs();
            btnTrends.Click += BtnTrends_Click;

            Controls.AddRange(new Control[] { btnNeu, btnUpdate, btnDeaktiv, btnLeeren, btnTrends });

            // ── Initialisierung ───────────────────────────────────────────
            LoadKategorieFilter();
            LoadAlleProdukte();
        }

        // ── Daten laden ───────────────────────────────────────────────────────

        private void LoadAlleProdukte()
        {
            try
            {
                chkNurTrends.Checked = false;
                cmbKategorie.SelectedIndex = 0;
                txtSuche.Clear();
                dgv.DataSource = _repo.GetAllProdukte();
            }
            catch (Exception ex) { UiHelper.ShowError(ex); }
        }

        private void LoadKategorieFilter()
        {
            try
            {
                cmbKategorie.Items.Clear();
                foreach (var k in _repo.GetKategorien())
                    cmbKategorie.Items.Add(k);
                cmbKategorie.SelectedIndex = 0;
                cmbKategorie.SelectedIndexChanged += (s, e) => ApplyFilter();
            }
            catch (Exception ex) { UiHelper.ShowError(ex); }
        }

        private void ApplyFilter()
        {
            try
            {
                if (chkNurTrends.Checked)
                {
                    dgv.DataSource = _repo.GetErnährungstrends();
                    return;
                }
                string suche = txtSuche.Text.Trim();
                string kat = cmbKategorie.SelectedItem?.ToString() ?? "Alle";
                dgv.DataSource = string.IsNullOrEmpty(suche)
                    ? _repo.GetProdukteByKategorie(kat)
                    : _repo.SearchProdukte(suche);
            }
            catch (Exception ex) { UiHelper.ShowError(ex); }
        }

        // ── Auswahl aus Grid in Eingabefelder übernehmen ────────────────────

        private void Dgv_CellClick(object sender, DataGridViewCellEventArgs e)
        {
            if (e.RowIndex < 0) return;
            var row = dgv.Rows[e.RowIndex];

            txtName.Text = row.Cells["Name"].Value?.ToString();
            txtBeschreibung.Text = row.Cells["Beschreibung"].Value?.ToString();
            txtPreis.Text = row.Cells["Preis"].Value?.ToString();
            txtEinheitMenge.Text = row.Cells["EinheitMenge"].Value?.ToString();

            string kat = row.Cells["Kategorie"].Value?.ToString() ?? "";
            int katIdx = Array.IndexOf(_kategorien, kat);
            cmbKategorieEingabe.SelectedIndex = katIdx >= 0 ? katIdx : 0;

            string einh = row.Cells["EinheitTyp"].Value?.ToString() ?? "kg";
            int einIdx = Array.IndexOf(_einheitTypen, einh);
            cmbEinheitTyp.SelectedIndex = einIdx >= 0 ? einIdx : 0;

            chkIstTrend.Checked = Convert.ToBoolean(row.Cells["IstErnährungstrend"].Value);
            chkIstAktiv.Checked = Convert.ToBoolean(row.Cells["IstAktiv"].Value);
        }

        // ── Button-Handler ────────────────────────────────────────────────────

        private void BtnNeu_Click(object sender, EventArgs e)
        {
            try
            {
                if (!ValidateInput(out decimal preis, out decimal menge)) return;
                _repo.AddProdukt(txtName.Text.Trim(), txtBeschreibung.Text.Trim(),
                    cmbKategorieEingabe.SelectedItem.ToString(),
                    preis, menge, cmbEinheitTyp.SelectedItem.ToString(),
                    chkIstTrend.Checked);
                LoadAlleProdukte();
                UiHelper.ShowInfo("Produkt wurde angelegt.");
                ClearInputs();
            }
            catch (Exception ex) { UiHelper.ShowError(ex); }
        }

        private void BtnUpdate_Click(object sender, EventArgs e)
        {
            try
            {
                if (dgv.SelectedRows.Count == 0)
                {
                    UiHelper.ShowInfo("Bitte zuerst ein Produkt in der Tabelle auswählen.");
                    return;
                }
                if (!ValidateInput(out decimal preis, out decimal menge)) return;
                int id = Convert.ToInt32(dgv.SelectedRows[0].Cells["ProduktID"].Value);
                _repo.UpdateProdukt(id, txtName.Text.Trim(), txtBeschreibung.Text.Trim(),
                    cmbKategorieEingabe.SelectedItem.ToString(),
                    preis, menge, cmbEinheitTyp.SelectedItem.ToString(),
                    chkIstTrend.Checked, chkIstAktiv.Checked);
                LoadAlleProdukte();
                UiHelper.ShowInfo("Produkt wurde aktualisiert.");
            }
            catch (Exception ex) { UiHelper.ShowError(ex); }
        }

        private void BtnDeaktiv_Click(object sender, EventArgs e)
        {
            try
            {
                if (dgv.SelectedRows.Count == 0)
                {
                    UiHelper.ShowInfo("Bitte zuerst ein Produkt auswählen.");
                    return;
                }
                int id = Convert.ToInt32(dgv.SelectedRows[0].Cells["ProduktID"].Value);
                string name = dgv.SelectedRows[0].Cells["Name"].Value?.ToString();
                if (!UiHelper.Confirm($"Produkt \"{name}\" wirklich deaktivieren?\n(Bestelldaten bleiben erhalten)"))
                    return;
                _repo.DeactivateProdukt(id);
                LoadAlleProdukte();
                UiHelper.ShowInfo("Produkt wurde deaktiviert.");
            }
            catch (Exception ex) { UiHelper.ShowError(ex); }
        }

        private void BtnTrends_Click(object sender, EventArgs e)
        {
            string info =
                "Aktuelle Ernährungstrends im Sortiment von Kraut & Rüben:\n\n" +
                "Superfood-Box\n" +
                "  Enthält z. B. Brokkoli, Spinat, Grünkohl, Chia-Samen – reich an Antioxidantien.\n\n" +
                "Rohkost-Box\n" +
                "  Ideal für Rohkost-Ernährung: Karotten, Rote Bete, Kohlrabi, Sellerie.\n\n" +
                "Kräuter-Box Premium\n" +
                "  Frische Küchenkräuter: Basilikum, Rosmarin, Thymian, Petersilie, Minze.\n\n" +
                "Detox-Box\n" +
                "  Entgiftend: Ingwer, Kurkuma, Petersilie, Gurke, Zitrone (Bio).\n\n" +
                "Saisonale Box\n" +
                "  Wechselndes Sortiment nach Saison und Regionalität.\n\n" +
                "Fermentier-Box\n" +
                "  Alles für die Fermentation: Weißkohl, Rotkohl, Rüben, Chinakohl.\n\n" +
                "Tipp: Produkte als Ernährungstrend markieren, um sie im Filter zu sehen.";

            MessageBox.Show(info, "Ernährungstrends bei Kraut & Rüben",
                MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        // ── Validierung & Hilfsmethoden ───────────────────────────────────────

        private bool ValidateInput(out decimal preis, out decimal menge)
        {
            preis = 0; menge = 0;
            if (string.IsNullOrWhiteSpace(txtName.Text))
            {
                UiHelper.ShowInfo("Produktname ist ein Pflichtfeld.");
                return false;
            }
            if (!decimal.TryParse(txtPreis.Text.Replace(",", "."),
                    System.Globalization.NumberStyles.Any,
                    System.Globalization.CultureInfo.InvariantCulture, out preis) || preis < 0)
            {
                UiHelper.ShowInfo("Bitte einen gültigen Preis eingeben (z. B. 4,99).");
                return false;
            }
            if (!decimal.TryParse(txtEinheitMenge.Text.Replace(",", "."),
                    System.Globalization.NumberStyles.Any,
                    System.Globalization.CultureInfo.InvariantCulture, out menge) || menge <= 0)
            {
                UiHelper.ShowInfo("Bitte eine gültige Mengenzahl eingeben (z. B. 1 oder 0,5).");
                return false;
            }
            return true;
        }

        private void ClearInputs()
        {
            txtName.Clear();
            txtBeschreibung.Clear();
            txtPreis.Clear();
            txtEinheitMenge.Text = "1";
            cmbKategorieEingabe.SelectedIndex = 0;
            cmbEinheitTyp.SelectedIndex = 0;
            chkIstTrend.Checked = false;
            chkIstAktiv.Checked = true;
            dgv.ClearSelection();
        }
    }
}

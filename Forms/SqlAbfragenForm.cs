using System;
using System.Windows.Forms;
using KrautUndRuebenApp.Data;
using KrautUndRuebenApp.Utils;

namespace KrautUndRuebenApp.Forms
{
    public class SqlAbfragenForm : Form
    {
        private readonly SqlQueryRepository _repo = new SqlQueryRepository();
        private readonly DataGridView dgv = new DataGridView();
        private readonly TextBox txtSql = new TextBox();

        public SqlAbfragenForm()
        {
            Text = "SQL-Abfragen";
            Width = 1200; Height = 770;
            StartPosition = FormStartPosition.CenterScreen;

            // Top = 20 statt 10, damit der Hinweistext nicht abgeschnitten wirkt
            Controls.Add(new Label
            {
                Text = "Demo-Hinweis: Hier werden die Pflichtabfragen sichtbar gemacht und direkt ausgeführt.",
                Left = 20, Top = 20, Width = 900, Height = 22
            });

            Button b1 = new Button { Text = "INNER JOIN", Left = 20, Top = 52, Width = 140 };
            Button b2 = new Button { Text = "LEFT JOIN", Left = 170, Top = 52, Width = 140 };
            Button b3 = new Button { Text = "RIGHT JOIN", Left = 320, Top = 52, Width = 140 };
            Button b4 = new Button { Text = "Subselect", Left = 470, Top = 52, Width = 140 };
            Button b5 = new Button { Text = "Aggregat", Left = 620, Top = 52, Width = 140 };

            txtSql.SetBounds(20, 100, 1140, 120);
            txtSql.Multiline = true;
            txtSql.ScrollBars = ScrollBars.Vertical;

            Button btnRun = new Button { Text = "Abfrage ausführen", Left = 20, Top = 230, Width = 180 };
            dgv.SetBounds(20, 275, 1140, 440);
            dgv.ReadOnly = true;
            dgv.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;

            b1.Click += (s, e) => LoadQuery(_repo.GetInnerJoinQuery());
            b2.Click += (s, e) => LoadQuery(_repo.GetLeftJoinQuery());
            b3.Click += (s, e) => LoadQuery(_repo.GetRightJoinQuery());
            b4.Click += (s, e) => LoadQuery(_repo.GetSubselectQuery());
            b5.Click += (s, e) => LoadQuery(_repo.GetAggregatQuery());
            btnRun.Click += (s, e) => ExecuteCurrentSql();

            Controls.AddRange(new Control[] { b1, b2, b3, b4, b5, txtSql, btnRun, dgv });
        }

        private void LoadQuery(string sql) { txtSql.Text = sql; ExecuteCurrentSql(); }
        private void ExecuteCurrentSql() { try { dgv.DataSource = _repo.ExecuteQuery(txtSql.Text); } catch (Exception ex) { UiHelper.ShowError(ex); } }
    }
}

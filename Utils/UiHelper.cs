using System;
using System.Windows.Forms;

namespace KrautUndRuebenApp.Utils
{
    public static class UiHelper
    {
        public static void ShowError(Exception ex) =>
            MessageBox.Show("Fehler: " + ex.Message, "Fehler",
                MessageBoxButtons.OK, MessageBoxIcon.Error);

        public static void ShowInfo(string message) =>
            MessageBox.Show(message, "Information",
                MessageBoxButtons.OK, MessageBoxIcon.Information);

        public static bool Confirm(string message) =>
            MessageBox.Show(message, "Bestätigung",
                MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes;
    }
}

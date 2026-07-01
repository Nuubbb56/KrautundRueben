namespace KrautUndRuebenApp.Models
{
    public class ProduktItem
    {
        public int    ProduktID   { get; set; }
        public string Name        { get; set; }
        public string Kategorie   { get; set; }
        public string Anzeigename => $"[{Kategorie}] {Name}";
    }
}

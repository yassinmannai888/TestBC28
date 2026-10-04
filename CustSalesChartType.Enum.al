namespace DefaultPublisher.TestBC28;

enum 50101 "Cust. Sales Chart Type"
{
    Extensible = false;

    value(0; Bar)
    {
        Caption = 'Histogramme';
    }
    value(1; HorizontalBar)
    {
        Caption = 'Barres horizontales';
    }
    value(2; Line)
    {
        Caption = 'Courbe';
    }
    value(3; Pie)
    {
        Caption = 'Secteurs';
    }
    value(4; Doughnut)
    {
        Caption = 'Anneau';
    }
}

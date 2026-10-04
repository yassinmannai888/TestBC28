namespace DefaultPublisher.TestBC28;

enum 50100 "Cust. Sales Indicator"
{
    Extensible = true;

    value(0; None)
    {
        Caption = '(Aucun)';
    }
    value(1; Sales)
    {
        Caption = 'Ventes DS';
    }
    value(2; Profit)
    {
        Caption = 'Marge DS';
    }
    value(3; ProfitPct)
    {
        Caption = 'Marge %';
    }
    value(4; EntryCount)
    {
        Caption = 'Nb écritures';
    }
    value(5; InvoiceCount)
    {
        Caption = 'Nb factures';
    }
    value(6; CrMemoCount)
    {
        Caption = 'Nb avoirs';
    }
    value(7; AvgInvoice)
    {
        Caption = 'Vente moyenne / facture';
    }
    value(8; Balance)
    {
        Caption = 'Solde DS';
    }
    value(9; SharePct)
    {
        Caption = 'Part du CA %';
    }
}

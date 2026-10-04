namespace DefaultPublisher.TestBC28;

using Microsoft.Sales.Customer;

table 50100 "Customer Sales Buffer"
{
    Caption = 'Tampon ventes client';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Customer No."; Code[20])
        {
            Caption = 'N° client';
            TableRelation = Customer;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Nom';
        }
        field(3; City; Text[30])
        {
            Caption = 'Ville';
        }
        field(10; "Sales (LCY)"; Decimal)
        {
            Caption = 'Ventes DS';
            AutoFormatType = 1;
        }
        field(11; "Profit (LCY)"; Decimal)
        {
            Caption = 'Marge DS';
            AutoFormatType = 1;
        }
        field(12; "Profit %"; Decimal)
        {
            Caption = 'Marge %';
            DecimalPlaces = 0 : 2;
        }
        field(13; "Entry Count"; Integer)
        {
            Caption = 'Nb écritures';
        }
        field(14; "Invoice Count"; Integer)
        {
            Caption = 'Nb factures';
        }
        field(15; "Cr. Memo Count"; Integer)
        {
            Caption = 'Nb avoirs';
        }
        field(16; "Avg. Invoice (LCY)"; Decimal)
        {
            Caption = 'Vente moyenne / facture';
            AutoFormatType = 1;
        }
        field(17; "Balance (LCY)"; Decimal)
        {
            Caption = 'Solde DS';
            AutoFormatType = 1;
        }
        field(18; "Share %"; Decimal)
        {
            Caption = 'Part du CA %';
            DecimalPlaces = 0 : 2;
        }
        field(19; "Last Posting Date"; Date)
        {
            Caption = 'Dernière écriture';
        }
        field(30; "Sort Value"; Decimal)
        {
            Caption = 'Valeur de tri';
        }
    }

    keys
    {
        key(PK; "Customer No.")
        {
            Clustered = true;
        }
        key(SortValue; "Sort Value")
        {
        }
    }
}

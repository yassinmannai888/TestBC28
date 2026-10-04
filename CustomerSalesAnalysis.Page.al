namespace DefaultPublisher.TestBC28;

using Microsoft.CRM.Team;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Customer;

page 50100 "Customer Sales Analysis"
{
    Caption = 'Analyse des ventes par client';
    PageType = Worksheet;
    SourceTable = "Customer Sales Buffer";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = Tasks;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                Caption = 'Filtres';

                field(DateFromField; DateFrom)
                {
                    Caption = 'Date début';
                    ToolTip = 'Date de comptabilisation de début des écritures client prises en compte.';

                    trigger OnValidate()
                    begin
                        RefreshData();
                    end;
                }
                field(DateToField; DateTo)
                {
                    Caption = 'Date fin';
                    ToolTip = 'Date de comptabilisation de fin des écritures client prises en compte. Le solde est calculé à cette date.';

                    trigger OnValidate()
                    begin
                        RefreshData();
                    end;
                }
                field(CustomerFilterField; CustomerFilter)
                {
                    Caption = 'Filtre client';
                    ToolTip = 'Filtre sur le n° client (ex. 10000..20000|30000).';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CustomerList: Page "Customer List";
                    begin
                        CustomerList.LookupMode(true);
                        if CustomerList.RunModal() <> Action::LookupOK then
                            exit(false);
                        Text := CustomerList.GetSelectionFilter();
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        RefreshData();
                    end;
                }
                field(PostingGroupFilterField; PostingGroupFilter)
                {
                    Caption = 'Filtre groupe compta client';
                    ToolTip = 'Filtre sur le groupe de comptabilisation client.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CustomerPostingGroup: Record "Customer Posting Group";
                    begin
                        if Page.RunModal(Page::"Customer Posting Groups", CustomerPostingGroup) <> Action::LookupOK then
                            exit(false);
                        Text := CustomerPostingGroup.Code;
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        RefreshData();
                    end;
                }
                field(SalespersonFilterField; SalespersonFilter)
                {
                    Caption = 'Filtre code vendeur';
                    ToolTip = 'Filtre sur le code vendeur de la fiche client.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        SalespersonsPurchasers: Page "Salespersons/Purchasers";
                    begin
                        SalespersonsPurchasers.LookupMode(true);
                        if SalespersonsPurchasers.RunModal() <> Action::LookupOK then
                            exit(false);
                        Text := SalespersonsPurchasers.GetSelectionFilter();
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        RefreshData();
                    end;
                }
                field(ShowCustomersWithoutSalesField; ShowCustomersWithoutSales)
                {
                    Caption = 'Afficher les clients sans ventes';
                    ToolTip = 'Indique si les clients sans ventes sur la période sont affichés.';

                    trigger OnValidate()
                    begin
                        RefreshData();
                    end;
                }
            }
            group(Indicators)
            {
                Caption = 'Indicateurs';

                group(ChartSettings)
                {
                    Caption = 'Graphique';

                    field(PrimaryIndicatorField; PrimaryIndicator)
                    {
                        Caption = 'Indicateur principal';
                        ToolTip = 'Indicateur affiché et utilisé pour classer les clients dans le graphique.';

                        trigger OnValidate()
                        begin
                            if PrimaryIndicator = PrimaryIndicator::None then
                                PrimaryIndicator := PrimaryIndicator::Sales;
                            UpdateChart();
                        end;
                    }
                    field(SecondaryIndicatorField; SecondaryIndicator)
                    {
                        Caption = 'Indicateur secondaire';
                        ToolTip = 'Indicateur affiché sur un second axe (sans effet sur les graphiques en secteurs/anneau).';

                        trigger OnValidate()
                        begin
                            UpdateChart();
                        end;
                    }
                    field(ChartTypeField; ChartType)
                    {
                        Caption = 'Type de graphique';
                        ToolTip = 'Type de représentation du graphique.';

                        trigger OnValidate()
                        begin
                            UpdateChart();
                        end;
                    }
                    field(TopNField; TopN)
                    {
                        Caption = 'Nombre de clients (top N)';
                        ToolTip = 'Nombre maximum de clients affichés dans le graphique (0 = tous).';
                        MinValue = 0;

                        trigger OnValidate()
                        begin
                            UpdateChart();
                        end;
                    }
                }
                group(Columns)
                {
                    Caption = 'Colonnes affichées';

                    field(ShowProfitField; ShowProfit)
                    {
                        Caption = 'Marge DS';
                        ToolTip = 'Affiche la colonne Marge DS.';

                        trigger OnValidate()
                        begin
                            CurrPage.Update(false);
                        end;
                    }
                    field(ShowProfitPctField; ShowProfitPct)
                    {
                        Caption = 'Marge %';
                        ToolTip = 'Affiche la colonne Marge %.';

                        trigger OnValidate()
                        begin
                            CurrPage.Update(false);
                        end;
                    }
                    field(ShowEntryCountField; ShowEntryCount)
                    {
                        Caption = 'Nb écritures';
                        ToolTip = 'Affiche le nombre d''écritures client.';

                        trigger OnValidate()
                        begin
                            CurrPage.Update(false);
                        end;
                    }
                    field(ShowDocCountField; ShowDocCount)
                    {
                        Caption = 'Nb factures / avoirs';
                        ToolTip = 'Affiche le nombre de factures et d''avoirs.';

                        trigger OnValidate()
                        begin
                            CurrPage.Update(false);
                        end;
                    }
                    field(ShowAvgInvoiceField; ShowAvgInvoice)
                    {
                        Caption = 'Vente moyenne / facture';
                        ToolTip = 'Affiche la vente moyenne par facture.';

                        trigger OnValidate()
                        begin
                            CurrPage.Update(false);
                        end;
                    }
                    field(ShowBalanceField; ShowBalance)
                    {
                        Caption = 'Solde DS';
                        ToolTip = 'Affiche le solde du client à la date de fin.';

                        trigger OnValidate()
                        begin
                            CurrPage.Update(false);
                        end;
                    }
                    field(ShowShareField; ShowShare)
                    {
                        Caption = 'Part du CA %';
                        ToolTip = 'Affiche la part de chaque client dans le chiffre d''affaires total.';

                        trigger OnValidate()
                        begin
                            CurrPage.Update(false);
                        end;
                    }
                    field(ShowLastPostingDateField; ShowLastPostingDate)
                    {
                        Caption = 'Dernière écriture';
                        ToolTip = 'Affiche la date de la dernière écriture sur la période.';

                        trigger OnValidate()
                        begin
                            CurrPage.Update(false);
                        end;
                    }
                }
            }
            group(Summary)
            {
                Caption = 'Synthèse';

                field(CustomerCountField; CustomerCount)
                {
                    Caption = 'Nb clients';
                    ToolTip = 'Nombre de clients affichés.';
                    Editable = false;
                }
                field(TotalSalesField; TotalSales)
                {
                    Caption = 'Total ventes DS';
                    ToolTip = 'Total des ventes DS des clients affichés.';
                    AutoFormatType = 1;
                    Editable = false;
                    Style = Strong;
                }
                field(TotalProfitField; TotalProfit)
                {
                    Caption = 'Total marge DS';
                    ToolTip = 'Total de la marge DS des clients affichés.';
                    AutoFormatType = 1;
                    Editable = false;
                }
                field(TotalProfitPctField; TotalProfitPct)
                {
                    Caption = 'Marge % globale';
                    ToolTip = 'Marge globale en pourcentage des ventes.';
                    DecimalPlaces = 0 : 2;
                    Editable = false;
                }
                field(AvgSalesPerCustomerField; AvgSalesPerCustomer)
                {
                    Caption = 'Vente moyenne / client';
                    ToolTip = 'Ventes DS moyennes par client affiché.';
                    AutoFormatType = 1;
                    Editable = false;
                }
            }
            group(ChartGroup)
            {
                Caption = 'Graphique';

                usercontrol(SalesChart; "Customer Sales Chart")
                {
                    ApplicationArea = All;

                    trigger ControlReady()
                    begin
                        ChartReady := true;
                        UpdateChart();
                    end;

                    trigger CustomerClicked(CustomerNo: Text)
                    begin
                        if Rec.Get(CopyStr(CustomerNo, 1, MaxStrLen(Rec."Customer No."))) then
                            CurrPage.Update(false);
                    end;
                }
            }
            repeater(Lines)
            {
                Editable = false;

                field("Customer No."; Rec."Customer No.")
                {
                    ToolTip = 'Numéro du client.';

                    trigger OnDrillDown()
                    var
                        Customer: Record Customer;
                    begin
                        if Customer.Get(Rec."Customer No.") then
                            Page.Run(Page::"Customer Card", Customer);
                    end;
                }
                field(Name; Rec.Name)
                {
                    ToolTip = 'Nom du client.';
                }
                field(City; Rec.City)
                {
                    ToolTip = 'Ville du client.';
                }
                field("Sales (LCY)"; Rec."Sales (LCY)")
                {
                    ToolTip = 'Ventes DS calculées à partir des écritures client de la période.';
                    Style = Strong;

                    trigger OnDrillDown()
                    begin
                        CustomerSalesAnalysisMgt.ShowLedgerEntries(Rec."Customer No.", DateFrom, DateTo, Enum::"Gen. Journal Document Type"::" ", false);
                    end;
                }
                field("Profit (LCY)"; Rec."Profit (LCY)")
                {
                    ToolTip = 'Marge DS calculée à partir des écritures client de la période.';
                    Visible = ShowProfit;
                }
                field("Profit %"; Rec."Profit %")
                {
                    ToolTip = 'Marge en pourcentage des ventes.';
                    Visible = ShowProfitPct;
                    StyleExpr = ProfitPctStyle;
                }
                field("Entry Count"; Rec."Entry Count")
                {
                    ToolTip = 'Nombre d''écritures client sur la période.';
                    Visible = ShowEntryCount;

                    trigger OnDrillDown()
                    begin
                        CustomerSalesAnalysisMgt.ShowLedgerEntries(Rec."Customer No.", DateFrom, DateTo, Enum::"Gen. Journal Document Type"::" ", false);
                    end;
                }
                field("Invoice Count"; Rec."Invoice Count")
                {
                    ToolTip = 'Nombre de factures sur la période.';
                    Visible = ShowDocCount;

                    trigger OnDrillDown()
                    begin
                        CustomerSalesAnalysisMgt.ShowLedgerEntries(Rec."Customer No.", DateFrom, DateTo, Enum::"Gen. Journal Document Type"::Invoice, true);
                    end;
                }
                field("Cr. Memo Count"; Rec."Cr. Memo Count")
                {
                    ToolTip = 'Nombre d''avoirs sur la période.';
                    Visible = ShowDocCount;

                    trigger OnDrillDown()
                    begin
                        CustomerSalesAnalysisMgt.ShowLedgerEntries(Rec."Customer No.", DateFrom, DateTo, Enum::"Gen. Journal Document Type"::"Credit Memo", true);
                    end;
                }
                field("Avg. Invoice (LCY)"; Rec."Avg. Invoice (LCY)")
                {
                    ToolTip = 'Ventes DS divisées par le nombre de factures.';
                    Visible = ShowAvgInvoice;
                }
                field("Balance (LCY)"; Rec."Balance (LCY)")
                {
                    ToolTip = 'Solde du client à la date de fin.';
                    Visible = ShowBalance;
                }
                field("Share %"; Rec."Share %")
                {
                    ToolTip = 'Part du client dans le total des ventes DS.';
                    Visible = ShowShare;
                }
                field("Last Posting Date"; Rec."Last Posting Date")
                {
                    ToolTip = 'Date de la dernière écriture client sur la période.';
                    Visible = ShowLastPostingDate;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Refresh)
            {
                Caption = 'Actualiser';
                ToolTip = 'Recalcule les lignes et le graphique à partir des écritures client.';
                Image = Refresh;

                trigger OnAction()
                begin
                    RefreshData();
                end;
            }
            action(ResetFilters)
            {
                Caption = 'Réinitialiser les filtres';
                ToolTip = 'Rétablit les filtres par défaut (début d''exercice à la date de travail).';
                Image = ClearFilter;

                trigger OnAction()
                begin
                    SetDefaultFilters();
                    RefreshData();
                end;
            }
        }
        area(Navigation)
        {
            action(LedgerEntries)
            {
                Caption = 'Écritures client';
                ToolTip = 'Affiche les écritures client de la ligne sélectionnée sur la période.';
                Image = CustomerLedger;
                Scope = Repeater;

                trigger OnAction()
                begin
                    CustomerSalesAnalysisMgt.ShowLedgerEntries(Rec."Customer No.", DateFrom, DateTo, Enum::"Gen. Journal Document Type"::" ", false);
                end;
            }
            action(CustomerCard)
            {
                Caption = 'Fiche client';
                ToolTip = 'Ouvre la fiche du client de la ligne sélectionnée.';
                Image = Customer;
                Scope = Repeater;
                RunObject = page "Customer Card";
                RunPageLink = "No." = field("Customer No.");
            }
        }
        area(Promoted)
        {
            actionref(Refresh_Promoted; Refresh)
            {
            }
            actionref(ResetFilters_Promoted; ResetFilters)
            {
            }
            actionref(LedgerEntries_Promoted; LedgerEntries)
            {
            }
            actionref(CustomerCard_Promoted; CustomerCard)
            {
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetDefaultSettings();
        SetDefaultFilters();
        LoadAndCalc();
    end;

    trigger OnAfterGetRecord()
    begin
        ProfitPctStyle := 'Standard';
        if Rec."Profit %" < 0 then
            ProfitPctStyle := 'Unfavorable'
        else
            if Rec."Profit %" >= 30 then
                ProfitPctStyle := 'Favorable';
    end;

    var
        CustomerSalesAnalysisMgt: Codeunit "Customer Sales Analysis Mgt.";
        DateFrom: Date;
        DateTo: Date;
        CustomerFilter: Text;
        PostingGroupFilter: Text;
        SalespersonFilter: Text;
        ShowCustomersWithoutSales: Boolean;
        PrimaryIndicator: Enum "Cust. Sales Indicator";
        SecondaryIndicator: Enum "Cust. Sales Indicator";
        ChartType: Enum "Cust. Sales Chart Type";
        TopN: Integer;
        ShowProfit: Boolean;
        ShowProfitPct: Boolean;
        ShowEntryCount: Boolean;
        ShowDocCount: Boolean;
        ShowAvgInvoice: Boolean;
        ShowBalance: Boolean;
        ShowShare: Boolean;
        ShowLastPostingDate: Boolean;
        ChartReady: Boolean;
        CustomerCount: Integer;
        TotalSales: Decimal;
        TotalProfit: Decimal;
        TotalProfitPct: Decimal;
        AvgSalesPerCustomer: Decimal;
        ProfitPctStyle: Text;
        DateRangeErr: Label 'La date de début doit être antérieure ou égale à la date de fin.';

    local procedure SetDefaultSettings()
    begin
        PrimaryIndicator := PrimaryIndicator::Sales;
        SecondaryIndicator := SecondaryIndicator::Profit;
        ChartType := ChartType::Bar;
        TopN := 10;
        ShowProfit := true;
        ShowProfitPct := true;
        ShowDocCount := true;
        ShowShare := true;
    end;

    local procedure SetDefaultFilters()
    begin
        DateFrom := CalcDate('<-CY>', WorkDate());
        DateTo := WorkDate();
        CustomerFilter := '';
        PostingGroupFilter := '';
        SalespersonFilter := '';
    end;

    local procedure RefreshData()
    begin
        if (DateFrom <> 0D) and (DateTo <> 0D) and (DateFrom > DateTo) then
            Error(DateRangeErr);

        LoadAndCalc();
        UpdateChart();
        CurrPage.Update(false);
    end;

    local procedure LoadAndCalc()
    begin
        CustomerSalesAnalysisMgt.LoadData(Rec, DateFrom, DateTo, CustomerFilter, PostingGroupFilter, SalespersonFilter, ShowCustomersWithoutSales);
        CalcTotals();
    end;

    local procedure CalcTotals()
    var
        CustomerSalesBuffer: Record "Customer Sales Buffer" temporary;
    begin
        CustomerSalesBuffer.Copy(Rec, true);
        CustomerSalesBuffer.Reset();
        CustomerSalesBuffer.CalcSums("Sales (LCY)", "Profit (LCY)");
        CustomerCount := CustomerSalesBuffer.Count();
        TotalSales := CustomerSalesBuffer."Sales (LCY)";
        TotalProfit := CustomerSalesBuffer."Profit (LCY)";
        TotalProfitPct := 0;
        AvgSalesPerCustomer := 0;
        if TotalSales <> 0 then
            TotalProfitPct := Round(TotalProfit / TotalSales * 100, 0.01);
        if CustomerCount <> 0 then
            AvgSalesPerCustomer := Round(TotalSales / CustomerCount);
    end;

    local procedure UpdateChart()
    begin
        if not ChartReady then
            exit;
        CurrPage.SalesChart.Render(
            CustomerSalesAnalysisMgt.BuildChartData(Rec, PrimaryIndicator, SecondaryIndicator, ChartType, TopN));
    end;
}

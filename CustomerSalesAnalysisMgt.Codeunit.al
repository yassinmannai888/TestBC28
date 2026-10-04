namespace DefaultPublisher.TestBC28;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

codeunit 50100 "Customer Sales Analysis Mgt."
{
    procedure LoadData(var CustomerSalesBuffer: Record "Customer Sales Buffer"; DateFrom: Date; DateTo: Date; CustomerFilter: Text; PostingGroupFilter: Text; SalespersonFilter: Text; ShowCustomersWithoutSales: Boolean)
    var
        Customer: Record Customer;
        TotalSales: Decimal;
    begin
        CustomerSalesBuffer.Reset();
        CustomerSalesBuffer.DeleteAll();

        if CustomerFilter <> '' then
            Customer.SetFilter("No.", CustomerFilter);
        if PostingGroupFilter <> '' then
            Customer.SetFilter("Customer Posting Group", PostingGroupFilter);
        if SalespersonFilter <> '' then
            Customer.SetFilter("Salesperson Code", SalespersonFilter);
        Customer.SetLoadFields("No.", Name, City);

        if Customer.FindSet() then
            repeat
                if FillBufferLine(CustomerSalesBuffer, Customer, DateFrom, DateTo, ShowCustomersWithoutSales) then
                    TotalSales += CustomerSalesBuffer."Sales (LCY)";
            until Customer.Next() = 0;

        if TotalSales <> 0 then
            if CustomerSalesBuffer.FindSet() then
                repeat
                    CustomerSalesBuffer."Share %" := Round(CustomerSalesBuffer."Sales (LCY)" / TotalSales * 100, 0.01);
                    CustomerSalesBuffer.Modify();
                until CustomerSalesBuffer.Next() = 0;

        if CustomerSalesBuffer.FindFirst() then;
    end;

    local procedure FillBufferLine(var CustomerSalesBuffer: Record "Customer Sales Buffer"; var Customer: Record Customer; DateFrom: Date; DateTo: Date; ShowCustomersWithoutSales: Boolean): Boolean
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BalanceCustomer: Record Customer;
    begin
        CustLedgerEntry.SetCurrentKey("Customer No.", "Document Type", "Posting Date", "Currency Code");
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.SetRange("Posting Date", DateFrom, DateTo);
        CustLedgerEntry.CalcSums("Sales (LCY)", "Profit (LCY)");

        CustomerSalesBuffer.Init();
        CustomerSalesBuffer."Customer No." := Customer."No.";
        CustomerSalesBuffer.Name := Customer.Name;
        CustomerSalesBuffer.City := Customer.City;
        CustomerSalesBuffer."Sales (LCY)" := CustLedgerEntry."Sales (LCY)";
        CustomerSalesBuffer."Profit (LCY)" := CustLedgerEntry."Profit (LCY)";
        CustomerSalesBuffer."Entry Count" := CustLedgerEntry.Count();

        if (CustomerSalesBuffer."Entry Count" = 0) and not ShowCustomersWithoutSales then
            exit(false);
        if (CustomerSalesBuffer."Sales (LCY)" = 0) and not ShowCustomersWithoutSales then
            exit(false);

        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustomerSalesBuffer."Invoice Count" := CustLedgerEntry.Count();
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
        CustomerSalesBuffer."Cr. Memo Count" := CustLedgerEntry.Count();

        if CustomerSalesBuffer."Sales (LCY)" <> 0 then
            CustomerSalesBuffer."Profit %" := Round(CustomerSalesBuffer."Profit (LCY)" / CustomerSalesBuffer."Sales (LCY)" * 100, 0.01);
        if CustomerSalesBuffer."Invoice Count" <> 0 then
            CustomerSalesBuffer."Avg. Invoice (LCY)" := Round(CustomerSalesBuffer."Sales (LCY)" / CustomerSalesBuffer."Invoice Count");

        CustomerSalesBuffer."Last Posting Date" := GetLastPostingDate(Customer."No.", DateFrom, DateTo);

        BalanceCustomer.Get(Customer."No.");
        BalanceCustomer.SetRange("Date Filter", 0D, DateTo);
        BalanceCustomer.CalcFields("Net Change (LCY)");
        CustomerSalesBuffer."Balance (LCY)" := BalanceCustomer."Net Change (LCY)";

        CustomerSalesBuffer.Insert();
        exit(true);
    end;

    local procedure GetLastPostingDate(CustomerNo: Code[20]; DateFrom: Date; DateTo: Date): Date
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetCurrentKey("Customer No.", "Posting Date");
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Posting Date", DateFrom, DateTo);
        CustLedgerEntry.SetLoadFields("Posting Date");
        if CustLedgerEntry.FindLast() then
            exit(CustLedgerEntry."Posting Date");
    end;

    procedure GetIndicatorValue(CustomerSalesBuffer: Record "Customer Sales Buffer"; Indicator: Enum "Cust. Sales Indicator"): Decimal
    begin
        case Indicator of
            Indicator::Sales:
                exit(CustomerSalesBuffer."Sales (LCY)");
            Indicator::Profit:
                exit(CustomerSalesBuffer."Profit (LCY)");
            Indicator::ProfitPct:
                exit(CustomerSalesBuffer."Profit %");
            Indicator::EntryCount:
                exit(CustomerSalesBuffer."Entry Count");
            Indicator::InvoiceCount:
                exit(CustomerSalesBuffer."Invoice Count");
            Indicator::CrMemoCount:
                exit(CustomerSalesBuffer."Cr. Memo Count");
            Indicator::AvgInvoice:
                exit(CustomerSalesBuffer."Avg. Invoice (LCY)");
            Indicator::Balance:
                exit(CustomerSalesBuffer."Balance (LCY)");
            Indicator::SharePct:
                exit(CustomerSalesBuffer."Share %");
        end;
        exit(0);
    end;

    /// <summary>
    /// Construit le JSON attendu par le control add-in : les N premiers clients triés sur l'indicateur principal.
    /// </summary>
    procedure BuildChartData(var CustomerSalesBuffer: Record "Customer Sales Buffer"; PrimaryIndicator: Enum "Cust. Sales Indicator"; SecondaryIndicator: Enum "Cust. Sales Indicator"; ChartType: Enum "Cust. Sales Chart Type"; TopN: Integer) ChartData: JsonObject
    var
        SortedBuffer: Record "Customer Sales Buffer" temporary;
        Labels: JsonArray;
        Keys: JsonArray;
        PrimaryValues: JsonArray;
        SecondaryValues: JsonArray;
        Datasets: JsonArray;
        Dataset: JsonObject;
        Counter: Integer;
        HasSecondary: Boolean;
    begin
        if PrimaryIndicator = PrimaryIndicator::None then
            PrimaryIndicator := PrimaryIndicator::Sales;
        HasSecondary := (SecondaryIndicator <> SecondaryIndicator::None) and (SecondaryIndicator <> PrimaryIndicator) and
                        not (ChartType in [ChartType::Pie, ChartType::Doughnut]);

        SortedBuffer.Copy(CustomerSalesBuffer, true);
        SortedBuffer.Reset();
        if SortedBuffer.FindSet() then
            repeat
                SortedBuffer."Sort Value" := GetIndicatorValue(SortedBuffer, PrimaryIndicator);
                SortedBuffer.Modify();
            until SortedBuffer.Next() = 0;

        SortedBuffer.SetCurrentKey("Sort Value");
        SortedBuffer.Ascending(false);
        if SortedBuffer.FindSet() then
            repeat
                Counter += 1;
                if SortedBuffer.Name <> '' then
                    Labels.Add(SortedBuffer.Name)
                else
                    Labels.Add(SortedBuffer."Customer No.");
                Keys.Add(SortedBuffer."Customer No.");
                PrimaryValues.Add(GetIndicatorValue(SortedBuffer, PrimaryIndicator));
                if HasSecondary then
                    SecondaryValues.Add(GetIndicatorValue(SortedBuffer, SecondaryIndicator));
            until (SortedBuffer.Next() = 0) or ((TopN > 0) and (Counter >= TopN));

        Dataset.Add('label', Format(PrimaryIndicator));
        Dataset.Add('data', PrimaryValues);
        Datasets.Add(Dataset);

        if HasSecondary then begin
            Clear(Dataset);
            Dataset.Add('label', Format(SecondaryIndicator));
            Dataset.Add('data', SecondaryValues);
            Dataset.Add('secondary', true);
            Datasets.Add(Dataset);
        end;

        ChartData.Add('chartType', GetChartTypeCode(ChartType));
        ChartData.Add('title', StrSubstNo(ChartTitleLbl, Format(PrimaryIndicator), Counter));
        ChartData.Add('labels', Labels);
        ChartData.Add('keys', Keys);
        ChartData.Add('datasets', Datasets);
    end;

    local procedure GetChartTypeCode(ChartType: Enum "Cust. Sales Chart Type"): Text
    begin
        case ChartType of
            ChartType::HorizontalBar:
                exit('horizontalBar');
            ChartType::Line:
                exit('line');
            ChartType::Pie:
                exit('pie');
            ChartType::Doughnut:
                exit('doughnut');
        end;
        exit('bar');
    end;

    procedure ShowLedgerEntries(CustomerNo: Code[20]; DateFrom: Date; DateTo: Date; DocumentType: Enum "Gen. Journal Document Type"; FilterOnDocumentType: Boolean)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetCurrentKey("Customer No.", "Posting Date");
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Posting Date", DateFrom, DateTo);
        if FilterOnDocumentType then
            CustLedgerEntry.SetRange("Document Type", DocumentType);
        Page.Run(Page::"Customer Ledger Entries", CustLedgerEntry);
    end;

    var
        ChartTitleLbl: Label '%1 - top %2 clients', Comment = '%1 = indicateur, %2 = nombre de clients';
}

// Welcome to your new AL extension.
// Remember that object names and IDs should be unique across all extensions.
// AL snippets start with t*, like tpageext - give them a try and happy coding!

namespace DefaultPublisher.TestBC28;

using Microsoft.Sales.Customer;

pageextension 50100 CustomerListExt extends "Customer List"
{
    actions
    {
        addlast(Reporting)
        {
            action(CustomerSalesAnalysis)
            {
                ApplicationArea = All;
                Caption = 'Analyse des ventes par client';
                Image = AnalysisView;
                ToolTip = 'Analyse les ventes de chaque client à partir des écritures client, avec filtres, indicateurs et graphique.';
                RunObject = page "Customer Sales Analysis";
            }
        }
    }

    trigger OnOpenPage();
    begin
        ShowTypewriterMessage('Bienvenue dans la liste des clients !');
    end;

    local procedure ShowTypewriterMessage(FullText: Text)
    var
        Window: Dialog;
        i: Integer;
    begin
        if not GuiAllowed() then
            exit;

        Window.Open('#1########################################');
        for i := 1 to StrLen(FullText) do begin
            Window.Update(1, CopyStr(FullText, 1, i) + '|');
            Sleep(60);
        end;
        Window.Update(1, FullText);
        Sleep(700);
        Window.Close();

        Message(FullText);
    end;
}
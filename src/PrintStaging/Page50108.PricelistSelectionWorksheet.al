/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-12
    Description: Worksheet to select pricelists for inclusion in PDF printout.
*/

page 50108 "Price List Selection Worksheet"
{
    PageType = Worksheet;
    SourceTable = "Price List Print Line";
    SourceTableView = sorting("Worksheet Code", "Sequence");
    UsageCategory = Tasks;
    ApplicationArea = All;
    Caption = 'ABAS Print Price List';

    layout
    {
        area(Content)
        {
            part(CatalogLines; "Price Selection Lines Subpart")
            {
                ApplicationArea = All;
                SubPageLink = "Worksheet Code" = field("Worksheet Code");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PrintCatalog)
            {
                Caption = 'Generate PDF Catalog';
                Image = PrintReport;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    PrintSelection: Record "Price List Print Line";
                begin
                    PrintSelection.Reset();
                    PrintSelection.SetRange("Worksheet Code", 'GLOBAL');

                    if not PrintSelection.IsEmpty() then
                        Report.Run(Report::"Combined Price List Report", true, false, PrintSelection)
                    else
                        Message('The worksheet is empty. Please click "Fetch Active Price Lists" before printing.');
                end;
            }
        }
    }
    trigger OnOpenPage()
    var
        SetupCheck: Record "Price List Print Line";
    begin
        begin
            Rec.FilterGroup(2);
            Rec.SetRange("Worksheet Code", 'GLOBAL');
            Rec.FilterGroup(0);
        end;

        SetupCheck.SetRange("Worksheet Code", 'GLOBAL');
        if SetupCheck.IsEmpty() then begin
            Rec.PopulatePriceLists();
            CurrPage.Update(false);
        end;
    end;
}
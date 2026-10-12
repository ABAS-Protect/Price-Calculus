page 50108 "Price List Selection Worksheet"
{
    PageType = Worksheet;
    SourceTable = "Price List Print Line";
    SourceTableView = sorting("User ID", "Sequence");
    UsageCategory = Tasks;
    ApplicationArea = All;
    Caption = 'ABAS Print Pricelist';

    layout
    {
        area(Content)
        {
            part(CatalogLines; "Price Selection Lines Subpart")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(FetchPriceLists)
            {
                Caption = 'Fetch Active Price Lists';
                Image = RefreshLines;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    CurrPage.CatalogLines.PAGE.TriggerPopulate();
                end;
            }

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
                    PrintSelection.SetRange("User ID", UserId());

                    if not PrintSelection.IsEmpty() then
                        Report.Run(Report::"Combined Price List Report", true, false, PrintSelection)
                    else
                        Message('The worksheet is empty. Please click "Fetch Active Price Lists" before printing.');
                end;
            }
        }
    }
}
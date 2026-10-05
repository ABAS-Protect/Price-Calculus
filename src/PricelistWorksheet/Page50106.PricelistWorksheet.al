/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-02
    Description: Handle price lines in custom worksheet.
*/

page 50106 "ABAS Price List Worksheet"
{
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = Tasks;
    SourceTable = "Worksheet Header";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Control Panel';

                field("Price List Code"; Rec."Price List Code")
                {
                    ApplicationArea = All;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        PriceListHeader: Record "Price List Header";
                    begin
                        PriceListHeader.SetRange("Price Type", PriceListHeader."Price Type"::Sale);
                        PriceListHeader.SetFilter("Amount Type", '<>%1', PriceListHeader."Amount Type"::Discount);

                        if Page.RunModal(Page::"Sales Price Lists", PriceListHeader) = Action::LookupOK then begin
                            Rec.Validate("Price List Code", PriceListHeader.Code);
                            Rec.Modify();
                            SyncSubpageState();
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        Rec.Modify();
                        SyncSubpageState();
                    end;
                }
                field("Price List Description"; Rec."Price List Description")
                {
                    ApplicationArea = All;
                }
                field("Comparison Baseline"; Rec."Comparison Baseline")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Rec.Modify();
                        SyncSubpageState();
                    end;
                }
            }

            part(PriceLines; "Worksheet Price Lines Subpart")
            {
                ApplicationArea = All;
                SubPageLink = "Price List Code" = field("Price List Code");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ApplySalesPrice)
            {
                Caption = 'Sales Price ➡️ Unit Price';
                ApplicationArea = All;
                Image = CopyDimensions;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Rec.TestField("Price List Code");
                    CurrPage.PriceLines.PAGE.CopySalesPriceToUnitPrice(Rec."Price List Code");
                    CurrPage.Update(false);
                end;
            }
            action(ApplyNetPrice)
            {
                Caption = 'Net Price ➡️ Unit Price';
                ApplicationArea = All;
                Image = CopyDimensions;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Rec.TestField("Price List Code");
                    CurrPage.PriceLines.PAGE.CopyNetPriceToUnitPrice(Rec."Price List Code");
                    CurrPage.Update(false);
                end;
            }
            action(CommitPriceList)
            {
                Caption = 'Publish Updates to Price List';
                ApplicationArea = All;
                Image = PostOrder;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Rec.TestField("Price List Code");
                    if Confirm('Publish non-zero lines to the Price List?', false) then begin
                        CurrPage.PriceLines.PAGE.UpdateActualPriceList(Rec."Price List Code");
                        CurrPage.Update(false);
                    end;
                end;
            }
            action(CloseWorksheet)
            {
                Caption = 'Close';
                ApplicationArea = All;
                Image = Close;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;

    trigger OnAfterGetRecord()
    begin
        SyncSubpageState();
    end;

    local procedure SyncSubpageState()
    begin
        CurrPage.PriceLines.PAGE.SetComparisonBaseline(Rec."Comparison Baseline");
    end;
}
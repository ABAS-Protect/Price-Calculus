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
    Caption = 'ABAS Price List Worksheet';

    AccessByPermission = TableData "Worksheet Header" = RM;

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
                            EvaluateActionVisibility();
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        Rec.Modify();
                        EvaluateActionVisibility();
                    end;
                }
                field("Price List Description"; Rec."Price List Description")
                {
                    ApplicationArea = All;
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
            // Copy calculated sales prices to price list unit prices (worksheet only).
            action(ApplySalesPrice)
            {
                Caption = 'Sales Price ➡️ Unit Price';
                ApplicationArea = All;
                Image = CopyDimensions;
                Promoted = true;
                PromotedCategory = Process;
                Visible = SalesPriceVisible;

                trigger OnAction()
                begin
                    Rec.TestField("Price List Code");
                    CurrPage.PriceLines.PAGE.CopySalesPriceToUnitPrice(Rec."Price List Code");
                    CurrPage.Update(false);
                end;
            }
            // Copy calculated net prices to price list unit prices (worksheet only).
            action(ApplyNetPrice)
            {
                Caption = 'Net Price ➡️ Unit Price';
                ApplicationArea = All;
                Image = CopyDimensions;
                Promoted = true;
                PromotedCategory = Process;
                Visible = NetPriceVisible;

                trigger OnAction()
                begin
                    Rec.TestField("Price List Code");
                    CurrPage.PriceLines.PAGE.CopyNetPriceToUnitPrice(Rec."Price List Code");
                    CurrPage.Update(false);
                end;
            }
            // Commit price list unit prices (worksheet) to actual price list lines.
            action(CommitPriceList)
            {
                Caption = 'Publish Updates to Price List';
                ApplicationArea = All;
                Image = PostOrder;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    PublishMsg: Label 'Publish non-zero lines to the Price List?';
                begin
                    Rec.TestField("Price List Code");
                    if Confirm(PublishMsg, false) then begin
                        CurrPage.PriceLines.PAGE.UpdateActualPriceList(Rec."Price List Code");
                        CurrPage.Update(false);
                    end;
                end;
            }
            action(OpenCatalogBuilder)
            {
                Caption = 'Print Price List';
                ApplicationArea = All;
                Image = Report;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Page.Run(Page::"Price List Selection Worksheet");
                end;
            }
        }
    }

    var
        LastPriceListCode: Code[20];
        SalesPriceVisible: Boolean;
        NetPriceVisible: Boolean;

    trigger OnOpenPage()
    begin
        Clear(LastPriceListCode);
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;

    // Fetch price list lines.
    trigger OnAfterGetRecord()
    begin
        if (Rec."Price List Code" <> LastPriceListCode) then begin
            CurrPage.PriceLines.PAGE.ClearStagedPrices();
            LastPriceListCode := Rec."Price List Code";
        end;

        EvaluateActionVisibility();
    end;

    local procedure EvaluateActionVisibility()
    var
        PriceListHeader: Record "Price List Header";
    begin
        SalesPriceVisible := false;
        NetPriceVisible := false;

        if Rec."Price List Code" <> '' then begin
            if PriceListHeader.Get(Rec."Price List Code") then begin
                SalesPriceVisible := PriceListHeader."Amount Type" = PriceListHeader."Amount Type"::Price;
                NetPriceVisible := PriceListHeader."Amount Type" = PriceListHeader."Amount Type"::Any;
            end;
        end;
    end;
}
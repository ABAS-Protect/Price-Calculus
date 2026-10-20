/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-02
    Description: Handle price lines in custom worksheet.
*/

namespace ABAS.ABAS_Price_Calculus;

using Microsoft.Pricing.PriceList;
using Microsoft.Sales.Pricing;

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
                    ToolTip = 'Price List Code';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        PriceListHeader: Record "Price List Header";
                    begin
                        PriceListHeader.SetRange("Price Type", PriceListHeader."Price Type"::Sale);
                        PriceListHeader.SetFilter("Amount Type", '<>%1', PriceListHeader."Amount Type"::Discount);

                        if Page.RunModal(Page::"Sales Price Lists", PriceListHeader) = Action::LookupOK then begin
                            Rec.Validate("Price List Code", PriceListHeader.Code);
                            Rec.Modify();
                            this.EvaluateActionVisibility();
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        Rec.Modify();
                        this.EvaluateActionVisibility();
                    end;
                }
                field("Price List Description"; Rec."Price List Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Price List Description';
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
                ToolTip = 'Copy calculated sales prices to price list new unit prices';
                Image = CopyDimensions;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Visible = this.SalesPriceVisible;

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
                ToolTip = 'Copy calculated net prices to price list new unit prices';
                Image = CopyDimensions;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Visible = this.NetPriceVisible;

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
                ToolTip = 'Commit price list unit prices (worksheet) to actual price list lines';
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
                ToolTip = 'Open worksheet';
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
        Clear(this.LastPriceListCode);
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;

    // Fetch price list lines.
    trigger OnAfterGetRecord()
    begin
        if (Rec."Price List Code" <> this.LastPriceListCode) then begin
            CurrPage.PriceLines.PAGE.ClearStagedPrices();
            this.LastPriceListCode := Rec."Price List Code";
        end;

        this.EvaluateActionVisibility();
    end;

    local procedure EvaluateActionVisibility()
    var
        PriceListHeader: Record "Price List Header";
    begin
        this.SalesPriceVisible := false;
        this.NetPriceVisible := false;

        if Rec."Price List Code" <> '' then
            if PriceListHeader.Get(Rec."Price List Code") then begin
                this.SalesPriceVisible := PriceListHeader."Amount Type" = PriceListHeader."Amount Type"::Price;
                this.NetPriceVisible := PriceListHeader."Amount Type" = PriceListHeader."Amount Type"::Any;
            end;
    end;
}
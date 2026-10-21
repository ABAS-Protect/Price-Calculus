/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-06
    Description: Keep items from other price lists off the standard price list.
*/

namespace ABAS.ABAS_Price_Calculus;

using Microsoft.Pricing.PriceList;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Setup;

pageextension 50110 "StandardPriceListExt" extends "Sales Price Lists"
{
    actions
    {
        addlast(processing)
        {
            action(AnalyzeConflicts)
            {
                ApplicationArea = All;
                Caption = 'Analyze Conflicting Prices';
                ToolTip = 'Scan lists and count conflicting lines with standard price list.';
                Image = ViewCheck;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    PriceListHeader: Record "Price List Header";
                    SalesReceivablesSetup: Record "Sales & Receivables Setup";
                    SalesPriceMgt: Codeunit "Filter Standard Price List";
                    TargetPriceListCode: Code[20];
                    LinesFound: Integer;
                    LinesFoundMsg: Label '%1 conflicting lines would be deleted from Price List "%2".', Comment = '%1 = LinesFound; %2 = TargetPriceListCode';
                    NoLinesMsg: Label 'No conflicting lines found for Price List "%1".', Comment = '%1 = TargetPriceListCode';
                begin
                    SalesReceivablesSetup.Get();
                    TargetPriceListCode := SalesReceivablesSetup."Default Price List Code";

                    // Select standard price list if not set up in Sales & Receivables.
                    if TargetPriceListCode = '' then begin
                        PriceListHeader.Reset();
                        if Page.RunModal(Page::"Sales Price Lists", PriceListHeader) = Action::LookupOK then
                            TargetPriceListCode := PriceListHeader.Code;
                    end;

                    if TargetPriceListCode <> '' then begin
                        LinesFound := SalesPriceMgt.FilterStandardPriceList(TargetPriceListCode, true);
                        if LinesFound > 0 then
                            Message(LinesFoundMsg, LinesFound, TargetPriceListCode)
                        else
                            Message(NoLinesMsg, TargetPriceListCode);
                    end;
                end;
            }

            action(ExcludeSpecialPrices)
            {
                ApplicationArea = All;
                Caption = 'Remove Conflicting Prices';
                ToolTip = 'Permanently delete lines from standard price list that clash with other lists.';
                Image = DeleteRow;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    PriceListHeader: Record "Price List Header";
                    SalesReceivablesSetup: Record "Sales & Receivables Setup";
                    SalesPriceMgt: Codeunit "Filter Standard Price List";
                    TargetPriceListCode: Code[20];
                    LinesFound: Integer;
                    ConfirmRunQst: Label 'Permanently delete conflicting lines from Price List "%1"?', Comment = '%1 = TargetPriceListCode';
                    RemoveMsg: Label '%1 lines successfully removed from Price List "%2".', Comment = '%1 = LinesFound; %2 = TargetPriceListCode';
                begin
                    SalesReceivablesSetup.Get();
                    TargetPriceListCode := SalesReceivablesSetup."Default Price List Code";

                    // Select standard price list if not set up in Sales & Receivables.
                    if TargetPriceListCode = '' then begin
                        PriceListHeader.Reset();
                        if Page.RunModal(Page::"Sales Price Lists", PriceListHeader) = Action::LookupOK then
                            TargetPriceListCode := PriceListHeader.Code;
                    end;

                    if TargetPriceListCode <> '' then
                        if Confirm(StrSubstNo(ConfirmRunQst, TargetPriceListCode), false) then begin
                            LinesFound := SalesPriceMgt.FilterStandardPriceList(TargetPriceListCode, false);
                            Message(RemoveMsg, LinesFound, TargetPriceListCode);
                            CurrPage.Update(false);
                        end;
                end;
            }
        }
    }
}
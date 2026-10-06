/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-06
    Description: Keep items from other price lists off the standard price list.
*/

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
                ToolTip = 'Scan lists and count conflicting lines.';
                Image = ViewCheck;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    PriceListHeader: Record "Price List Header";
                    SalesPriceMgt: Codeunit "Filter Standard Price List";
                    LinesFound: Integer;
                    LinesFoundMsg: Label '%1 conflicting lines would be deleted from Price List "%2".';
                    NoLinesMsg: Label 'No conflicting lines found for Price List "%1".';
                begin
                    PriceListHeader.Reset();
                    if Page.RunModal(Page::"Sales Price Lists", PriceListHeader) = Action::LookupOK then begin
                        LinesFound := SalesPriceMgt.FilterStandardPriceList(PriceListHeader.Code, true);

                        if LinesFound > 0 then
                            Message(LinesFoundMsg, LinesFound, PriceListHeader.Code)
                        else
                            Message(NoLinesMsg, PriceListHeader.Code);
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
                    SalesPriceMgt: Codeunit "Filter Standard Price List";
                    LinesFound: Integer;
                    ConfirmRunQst: Label 'Permanently delete conflicting lines from Price List "%1"?';
                    RemoveMessage: Label '%1 lines successfully removed from Price List "%2".';
                begin
                    PriceListHeader.Reset();
                    if Page.RunModal(Page::"Sales Price Lists", PriceListHeader) = Action::LookupOK then begin
                        if Confirm(StrSubstNo(ConfirmRunQst, PriceListHeader.Code), false) then begin
                            LinesFound := SalesPriceMgt.FilterStandardPriceList(PriceListHeader.Code, false);
                            Message(RemoveMessage, LinesFound, PriceListHeader.Code);
                            CurrPage.Update(false);
                        end;
                    end;
                end;
            }
        }
    }
}
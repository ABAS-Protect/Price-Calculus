/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-06
    Description: Keep items from other price lists off the standard price list.
*/

namespace ABAS.ABAS_Price_Calculus;

using Microsoft.Pricing.PriceList;

codeunit 50107 "Filter Standard Price List"
{
    procedure FilterStandardPriceList(SelectedPriceListCode: Code[20]; DryRun: Boolean) DeletedCount: Integer
    var
        StandardLine: Record "Price List Line";
        SpecialLine: Record "Price List Line";
        TempActiveSpecialLine: Record "Price List Line" temporary;
        PriceListHeader: Record "Price List Header";
        LinesToDelete: Record "Price List Line";
        ShouldDelete: Boolean;
    begin
        if SelectedPriceListCode = '' then
            exit(0);

        DeletedCount := 0;

        if not DryRun then
            if PriceListHeader.Get(SelectedPriceListCode) then begin
                if PriceListHeader.Status = PriceListHeader.Status::Active then begin
                    PriceListHeader.Status := PriceListHeader.Status::Draft;
                    PriceListHeader.Modify(true);
                end;
            end else
                exit(0);

        SpecialLine.SetFilter("Price List Code", '<>%1', SelectedPriceListCode);
        SpecialLine.SetRange(Status, SpecialLine.Status::Active);
        SpecialLine.SetRange("Asset Type", SpecialLine."Asset Type"::Item);
        if SpecialLine.FindSet(false) then
            repeat
                TempActiveSpecialLine.Copy(SpecialLine);
                TempActiveSpecialLine.Insert();
            until SpecialLine.Next() = 0;

        StandardLine.SetRange("Price List Code", SelectedPriceListCode);
        StandardLine.SetRange("Asset Type", StandardLine."Asset Type"::Item);

        if StandardLine.FindSet(false) then
            repeat
                ShouldDelete := false;

                // Variant in common, delete variant.
                TempActiveSpecialLine.Reset();
                TempActiveSpecialLine.SetRange("Asset No.", StandardLine."Asset No.");
                TempActiveSpecialLine.SetRange("Variant Code", StandardLine."Variant Code");
                if not TempActiveSpecialLine.IsEmpty() then
                    ShouldDelete := true;

                // Standard has variant, price list does not (general coverage); delete variant.
                if (not ShouldDelete) and (StandardLine."Variant Code" <> '') then begin
                    TempActiveSpecialLine.SetRange("Variant Code", '');
                    if not TempActiveSpecialLine.IsEmpty() then
                        ShouldDelete := true;
                end;

                // Standard has general coverage but not actual variant, delete item number.
                if (not ShouldDelete) and (StandardLine."Variant Code" = '') then begin
                    TempActiveSpecialLine.SetFilter("Variant Code", '<>%1', '');
                    if not TempActiveSpecialLine.IsEmpty() then
                        ShouldDelete := true;
                end;

                if ShouldDelete then begin
                    DeletedCount += 1;

                    if not DryRun then begin
                        LinesToDelete.Get(StandardLine."Price List Code", StandardLine."Line No.");
                        LinesToDelete.Mark(true);
                    end;
                end;
            until StandardLine.Next() = 0;

        // Mass execution.
        if (not DryRun) and (DeletedCount > 0) then begin
            LinesToDelete.MarkedOnly(true);
            LinesToDelete.DeleteAll(true);
        end;

        if not DryRun then begin
            PriceListHeader.Status := PriceListHeader.Status::Active;
            PriceListHeader.Modify(true);
        end;
    end;
}
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
        PriceListHeader: Record "Price List Header";
        StandardLineToDelete: Record "Price List Line";
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

        StandardLine.SetRange("Price List Code", SelectedPriceListCode);
        StandardLine.SetRange("Asset Type", StandardLine."Asset Type"::Item);

        if StandardLine.FindSet(false) then
            repeat
                ShouldDelete := false;

                // Variant in common, delete variant.
                SpecialLine.Reset();
                SpecialLine.SetFilter("Price List Code", '<>%1', SelectedPriceListCode);
                SpecialLine.SetRange("Asset Type", StandardLine."Asset Type"::Item);
                SpecialLine.SetRange("Asset No.", StandardLine."Asset No.");
                SpecialLine.SetRange("Variant Code", StandardLine."Variant Code");
                if not SpecialLine.IsEmpty() then
                    ShouldDelete := true;

                // Standard has variant, price list does not (general coverage); delete variant.
                if (not ShouldDelete) and (StandardLine."Variant Code" <> '') then begin
                    SpecialLine.Reset();
                    SpecialLine.SetFilter("Price List Code", '<>%1', SelectedPriceListCode);
                    SpecialLine.SetRange("Asset Type", StandardLine."Asset Type"::Item);
                    SpecialLine.SetRange("Asset No.", StandardLine."Asset No.");
                    SpecialLine.SetRange("Variant Code", '');
                    if not SpecialLine.IsEmpty() then
                        ShouldDelete := true;
                end;

                // Standard has general coverage but not actual variant, delete item number.
                if (not ShouldDelete) and (StandardLine."Variant Code" = '') then begin
                    SpecialLine.Reset();
                    SpecialLine.SetFilter("Price List Code", '<>%1', SelectedPriceListCode);
                    SpecialLine.SetRange("Asset Type", StandardLine."Asset Type"::Item);
                    SpecialLine.SetRange("Asset No.", StandardLine."Asset No.");
                    SpecialLine.SetFilter("Variant Code", '<>%1', '');
                    if not SpecialLine.IsEmpty() then
                        ShouldDelete := true;
                end;

                if ShouldDelete then begin
                    DeletedCount += 1;

                    if not DryRun then
                        if StandardLineToDelete.Get(StandardLine."Price List Code", StandardLine."Line No.") then
                            StandardLineToDelete.Delete(true);
                end;
            until StandardLine.Next() = 0;

        if not DryRun then begin
            PriceListHeader.Status := PriceListHeader.Status::Active;
            PriceListHeader.Modify(true);
        end;
    end;
}
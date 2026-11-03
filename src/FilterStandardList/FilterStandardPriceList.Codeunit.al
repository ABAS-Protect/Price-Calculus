/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-06
    Description: Keep items from other price lists off the standard price list.
*/

namespace ABAS.ABAS_Price_Calculus;

using Microsoft.Pricing.PriceList;

codeunit 50107 "Filter Standard Price List"
{
    procedure FilterStandardPriceList(SelectedPriceListCode: Code[20]; DryRun: Boolean; var TempChangeLogBuffer: Record "Price List Line" temporary) DeletedCount: Integer
    var
        StandardLine: Record "Price List Line";
        SpecialLine: Record "Price List Line";
        TempActiveSpecialLine: Record "Price List Line" temporary;
        PriceListHeader: Record "Price List Header";
        LinesToDelete: Record "Price List Line";
        ShouldDelete: Boolean;
        ConflictReason: Text[100];
        CompetingPriceListCode: Code[20];
        ExactItemVariantMsg: Label 'Exact item and variant match found in another price list.';
        ExactItemMsg: Label 'Exact item match (no variants) found in another price list.';
        GlobalItemMsg: Label 'A global item price (no variant) exists in another list.';
        SpecificVariantMsg: Label 'Specific variant prices exist for this item in another list.';
    begin
        if SelectedPriceListCode = '' then
            exit(0);

        DeletedCount := 0;
        TempChangeLogBuffer.Reset();
        TempChangeLogBuffer.DeleteAll();

        if not DryRun then
            if PriceListHeader.Get(SelectedPriceListCode) then begin
                if PriceListHeader.Status = PriceListHeader.Status::Active then begin
                    PriceListHeader.Status := PriceListHeader.Status::Draft;
                    PriceListHeader.Modify(false);
                end;
            end else
                exit(0);

        SpecialLine.SetFilter("Price List Code", '<>%1', SelectedPriceListCode);
        SpecialLine.SetRange(Status, SpecialLine.Status::Active);
        SpecialLine.SetRange("Asset Type", SpecialLine."Asset Type"::Item);
        SpecialLine.SetRange("Source Type", SpecialLine."Source Type"::"All Customers");

        if SpecialLine.FindSet(false) then
            repeat
                TempActiveSpecialLine.Init();
                TempActiveSpecialLine.TransferFields(SpecialLine);
                TempActiveSpecialLine.Insert();
            until SpecialLine.Next() = 0;

        StandardLine.SetRange("Price List Code", SelectedPriceListCode);
        StandardLine.SetRange("Asset Type", StandardLine."Asset Type"::Item);
        StandardLine.SetRange("Source Type", StandardLine."Source Type"::"All Customers");

        if StandardLine.FindSet(false) then
            repeat
                ShouldDelete := false;
                ConflictReason := '';
                CompetingPriceListCode := '';

                TempActiveSpecialLine.Reset();
                TempActiveSpecialLine.SetRange("Asset No.", StandardLine."Asset No.");

                if not TempActiveSpecialLine.IsEmpty() then begin
                    // Case 1: Exact Item and Variant match (or both are completely blank/no variants)
                    TempActiveSpecialLine.SetRange("Variant Code", StandardLine."Variant Code");
                    if TempActiveSpecialLine.FindFirst() then begin
                        ShouldDelete := true;
                        CompetingPriceListCode := TempActiveSpecialLine."Price List Code";
                        if StandardLine."Variant Code" <> '' then
                            ConflictReason := ExactItemVariantMsg
                        else
                            ConflictReason := ExactItemMsg;
                    end;

                    // Case 2: Standard line has a variant, but a global price (blank variant) exists elsewhere
                    if (not ShouldDelete) and (StandardLine."Variant Code" <> '') then begin
                        TempActiveSpecialLine.SetRange("Variant Code", '');
                        if TempActiveSpecialLine.FindFirst() then begin
                            ShouldDelete := true;
                            CompetingPriceListCode := TempActiveSpecialLine."Price List Code";
                            ConflictReason := GlobalItemMsg;
                        end;
                    end;

                    // Case 3: Standard line is global (blank variant), but specific variants exist elsewhere
                    if (not ShouldDelete) and (StandardLine."Variant Code" = '') then begin
                        TempActiveSpecialLine.SetFilter("Variant Code", '<>%1', '');
                        if TempActiveSpecialLine.FindFirst() then begin
                            ShouldDelete := true;
                            CompetingPriceListCode := TempActiveSpecialLine."Price List Code";
                            ConflictReason := SpecificVariantMsg;
                        end;
                    end;
                end;

                if ShouldDelete then begin
                    DeletedCount += 1;

                    TempChangeLogBuffer.Init();
                    TempChangeLogBuffer.TransferFields(StandardLine);
                    TempChangeLogBuffer.Description := ConflictReason;
                    TempChangeLogBuffer."Source No." := CompetingPriceListCode;
                    TempChangeLogBuffer.Insert();

                    if not DryRun then begin
                        LinesToDelete.Get(StandardLine."Price List Code", StandardLine."Line No.");
                        LinesToDelete.Mark(true);
                    end;
                end;
            until StandardLine.Next() = 0;

        if (not DryRun) and (DeletedCount > 0) then begin
            LinesToDelete.MarkedOnly(true);
            LinesToDelete.DeleteAll(true);
        end;

        if not DryRun then
            if PriceListHeader.Get(SelectedPriceListCode) then begin
                PriceListHeader.Status := PriceListHeader.Status::Active;
                PriceListHeader.Modify(false);
            end;
    end;
}
/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-02
    Description: Calculate work sheet lines, update Price List lines.
*/

page 50105 "Worksheet Price Lines Subpart"
{
    PageType = ListPart;
    SourceTable = "Price List Line";
    InsertAllowed = false;
    DeleteAllowed = false;
    Caption = ' ';

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Asset No."; Rec."Asset No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Item No.';
                    DrillDown = true;

                    trigger OnDrillDown()
                    var
                        Item: Record Item;
                    begin
                        if Item.Get(Rec."Asset No.") then
                            Page.Run(Page::"Item Card", Item);
                    end;
                }
                field(Description; Rec.Description) { ApplicationArea = All; Editable = false; }
                field("Variant Code"; Rec."Variant Code") { ApplicationArea = All; Editable = false; }

                field(ItemMarkup; ItemMarkup)
                {
                    ApplicationArea = All;
                    Caption = 'Overhead Markup %';
                    Editable = IsItemAsset;

                    trigger OnValidate()
                    var
                        Item: Record Item;
                    begin
                        if IsItemAsset and Item.Get(Rec."Asset No.") then begin
                            Item.Validate("COMP Markup", ItemMarkup);
                            Item.Modify(true);

                            ItemSalesPrice := Item."COMP Sales Price";
                            ItemNetPrice := Item."COMP Net Price";
                            CalculateDifferences();
                        end;
                    end;
                }
                field(ItemSalesPrice; ItemSalesPrice) { ApplicationArea = All; Caption = 'Sales Price (Calc.)'; Editable = false; }
                field(ItemNetPrice; ItemNetPrice) { ApplicationArea = All; Caption = 'Net Price (Calc.)'; Editable = false; }
                field(ItemComment; ItemComment)
                {
                    ApplicationArea = All;
                    Caption = 'Comment';

                    trigger OnValidate()
                    var
                        Item: Record Item;
                    begin
                        if IsItemAsset and Item.Get(Rec."Asset No.") then begin
                            Item."COMP Comment" := ItemComment;
                            Item.Modify(true);
                        end;
                    end;
                }

                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        CalculateDifferences();
                    end;
                }

                field(PriceDifference; PriceDifference) { ApplicationArea = All; Caption = 'Diff.'; Editable = false; StyleExpr = DifferenceStyle; }
                field(PriceDifferencePct; PriceDifferencePct) { ApplicationArea = All; Caption = 'Diff. (%)'; Editable = false; StyleExpr = DifferenceStyle; }
            }
        }
    }

    var
        ItemMarkup: Integer;
        ItemSalesPrice: Decimal;
        ItemNetPrice: Decimal;
        ItemComment: Text[100];
        PriceDifference: Decimal;
        PriceDifferencePct: Decimal;
        IsItemAsset: Boolean;
        DifferenceStyle: Text;
        CurrentBaseline: Option "Sales Price","Net Price";

    trigger OnAfterGetRecord()
    var
        Item: Record Item;
    begin
        ClearFields();

        if (Rec."Price List Code" = '') or (Rec."Asset No." = '') then
            exit;

        IsItemAsset := Rec."Asset Type" = Rec."Asset Type"::Item;
        if IsItemAsset and Item.Get(Rec."Asset No.") then begin
            ItemMarkup := Item."COMP Markup";
            ItemSalesPrice := Item."COMP Sales Price";
            ItemNetPrice := Item."COMP Net Price";
            ItemComment := Item."COMP Comment";
            CalculateDifferences();
        end;
    end;

    local procedure ClearFields()
    begin
        ItemMarkup := 0;
        ItemSalesPrice := 0;
        ItemNetPrice := 0;
        PriceDifference := 0;
        PriceDifferencePct := 0;
        IsItemAsset := false;
        DifferenceStyle := 'None';
    end;

    local procedure CalculateDifferences()
    var
        TargetBaselinePrice: Decimal;
    begin
        if CurrentBaseline = CurrentBaseline::"Net Price" then
            TargetBaselinePrice := ItemNetPrice
        else
            TargetBaselinePrice := ItemSalesPrice;

        if (Rec."Unit Price" <> 0) and (TargetBaselinePrice <> 0) then begin
            PriceDifference := Rec."Unit Price" - TargetBaselinePrice;
            PriceDifferencePct := (PriceDifference / TargetBaselinePrice) * 100;
        end else begin
            PriceDifference := 0;
            PriceDifferencePct := 0;
        end;

        if PriceDifference > 0 then
            DifferenceStyle := 'Favorable'
        else if PriceDifference < 0 then
            DifferenceStyle := 'Unfavorable'
        else
            DifferenceStyle := 'None';
    end;

    procedure SetComparisonBaseline(NewBaseline: Option "Sales Price","Net Price")
    begin
        CurrentBaseline := NewBaseline;
        CurrPage.Update(false);
    end;

    procedure CopySalesPriceToUnitPrice(PriceListCode: Code[20])
    var
        PriceListLine: Record "Price List Line";
        Item: Record Item;
    begin
        PriceListLine.SetRange("Price List Code", PriceListCode);
        PriceListLine.SetRange("Asset Type", PriceListLine."Asset Type"::Item);
        if PriceListLine.FindSet(true) then begin
            repeat
                if Item.Get(PriceListLine."Asset No.") and (Item."COMP Sales Price" <> 0) then begin
                    PriceListLine.Validate("Unit Price", Item."COMP Sales Price");
                    PriceListLine.Modify(true);
                end;
            until PriceListLine.Next() = 0;
        end;
    end;

    procedure CopyNetPriceToUnitPrice(PriceListCode: Code[20])
    var
        PriceListLine: Record "Price List Line";
        Item: Record Item;
    begin
        PriceListLine.SetRange("Price List Code", PriceListCode);
        PriceListLine.SetRange("Asset Type", PriceListLine."Asset Type"::Item);
        if PriceListLine.FindSet(true) then begin
            repeat
                if Item.Get(PriceListLine."Asset No.") and (Item."COMP Net Price" <> 0) then begin
                    PriceListLine.Validate("Unit Price", Item."COMP Net Price");
                    PriceListLine.Modify(true);
                end;
            until PriceListLine.Next() = 0;
        end;
    end;

    procedure UpdateActualPriceList(PriceListCode: Code[20])
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        DuplicatePriceLine: Record "Duplicate Price Line";
        PriceListManagement: Codeunit "Price List Management";
        OriginalStatus: Enum "Price Status";
    begin
        if PriceListHeader.Get(PriceListCode) then begin
            OriginalStatus := PriceListHeader.Status;

            if PriceListHeader.Status = PriceListHeader.Status::Active then begin
                PriceListHeader.Status := PriceListHeader.Status::Draft;
                PriceListHeader.Modify(false);
            end;

            PriceListLine.SetRange("Price List Code", PriceListCode);
            PriceListLine.SetRange("Asset No.", '');
            if not PriceListLine.IsEmpty() then
                PriceListLine.DeleteAll(false);

            PriceListLine.Reset();
            PriceListLine.SetRange("Price List Code", PriceListCode);
            PriceListLine.SetRange(Status, PriceListLine.Status::Draft);

            if PriceListManagement.FindDuplicatePrices(PriceListHeader, PriceListLine, true, DuplicatePriceLine) then begin
                DuplicatePriceLine.Reset();
                DuplicatePriceLine.SetRange("Price List Code", PriceListCode);
                DuplicatePriceLine.SetRange(Remove, true);

                if DuplicatePriceLine.FindSet() then begin
                    repeat
                        if PriceListLine.Get(DuplicatePriceLine."Price List Code", DuplicatePriceLine."Line No.") then
                            PriceListLine.Delete(false);
                    until DuplicatePriceLine.Next() = 0;
                end;
            end;

            PriceListManagement.ActivateDraftLines(PriceListHeader, true);

            if OriginalStatus = OriginalStatus::Active then begin
                PriceListHeader.Status := PriceListHeader.Status::Active;
                PriceListHeader.Modify(false);

                PriceListLine.Reset();
                PriceListLine.SetRange("Price List Code", PriceListCode);
                PriceListLine.SetRange(Status, PriceListLine.Status::Draft);
                if not PriceListLine.IsEmpty() then
                    PriceListLine.ModifyAll(Status, PriceListLine.Status::Active, false);
            end else begin
                PriceListHeader.Status := OriginalStatus;
                PriceListHeader.Modify(false);
            end;

            Message('Price lines successfully published.', PriceListCode);
        end;
    end;
}
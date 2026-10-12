/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-02
    Description: Calculate work sheet lines, update Price List lines.
*/

page 50105 "Worksheet Price Lines Subpart"
{
    PageType = ListPart;
    SourceTable = "Price List Line";
    SourceTableTemporary = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    Caption = ' ', Locked = true;

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

                    // Make Item Card link from Item No.
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

                // Main calculus parameter, triggers changes in sales and net prices on validation.
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
                field(WorkingUnitPrice; WorkingUnitPrice)
                {
                    ApplicationArea = All;
                    Caption = 'New Unit Price (Draft)';
                    Editable = true;

                    trigger OnValidate()
                    begin
                        SavePriceToMemory(Rec."Line No.", WorkingUnitPrice);
                        CalculateDifferences();
                    end;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(PriceDifference; PriceDifference) { ApplicationArea = All; Caption = 'Diff.'; Editable = false; StyleExpr = DifferenceStyle; }
                field(PriceDifferencePct; PriceDifferencePct) { ApplicationArea = All; Caption = 'Diff. (%)'; Editable = false; StyleExpr = DifferenceStyle; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            // Copy calculated sales price to price list unit price, row only.
            action(CopyRowSalesPrice)
            {
                ApplicationArea = All;
                Caption = 'Sales Price ➡️ Unit Price';
                Image = CopyFromTask;
                Scope = Repeater;

                trigger OnAction()
                begin
                    if ItemSalesPrice <> 0 then begin
                        WorkingUnitPrice := ItemSalesPrice;
                        SavePriceToMemory(Rec."Line No.", WorkingUnitPrice);
                    end;
                end;
            }

            // Copy calculated net price to price list unit price, row only.
            action(CopyRowNetPrice)
            {
                ApplicationArea = All;
                Caption = 'Net Price ➡️ Unit Price';
                Image = CopyFromTask;
                Scope = Repeater;

                trigger OnAction()
                begin
                    if ItemNetPrice <> 0 then begin
                        WorkingUnitPrice := ItemNetPrice;
                        SavePriceToMemory(Rec."Line No.", WorkingUnitPrice);
                    end;
                end;
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
        WorkingUnitPrice: Decimal;
        StagedPricesMap: Dictionary of [Integer, Decimal];

    trigger OnAfterGetRecord()
    var
        Item: Record Item;
    begin
        ClearFields();

        if not TryGetPriceFromMemory(Rec."Line No.", WorkingUnitPrice) then
            WorkingUnitPrice := Rec."Unit Price";

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

    // Calculate difference between calculated and actual price, using sales or net price.
    local procedure CalculateDifferences()
    var
        TargetBaselinePrice: Decimal;
    begin
        if CurrentBaseline = CurrentBaseline::"Net Price" then
            TargetBaselinePrice := ItemNetPrice
        else
            TargetBaselinePrice := ItemSalesPrice;

        if (WorkingUnitPrice <> 0) and (TargetBaselinePrice <> 0) then begin
            PriceDifference := WorkingUnitPrice - TargetBaselinePrice;
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

    // Baseline sales/net price for difference comparisons.
    procedure SetComparisonBaseline(NewBaseline: Option "Sales Price","Net Price")
    begin
        CurrentBaseline := NewBaseline;
        CurrPage.Update(false);
    end;

    // Copy calculated sales price to price list unit price (worksheet only).
    procedure CopySalesPriceToUnitPrice(PriceListCode: Code[20])
    var
        PriceListLineLoop: Record "Price List Line";
        Item: Record Item;
    begin
        PriceListLineLoop.CopyFilters(Rec);
        PriceListLineLoop.SetRange("Price List Code", PriceListCode);

        if PriceListLineLoop.FindSet() then
            repeat
                if (PriceListLineLoop."Asset Type" = PriceListLineLoop."Asset Type"::Item) and
                   Item.Get(PriceListLineLoop."Asset No.") and
                   (Item."COMP Sales Price" <> 0) then begin

                    // Save directly to our isolated execution memory map
                    SavePriceToMemory(PriceListLineLoop."Line No.", Item."COMP Sales Price");
                end;
            until PriceListLineLoop.Next() = 0;

        CurrPage.Update(false);
    end;

    // Copy calculated net price to price list unit price (worksheet only).
    procedure CopyNetPriceToUnitPrice(PriceListCode: Code[20])
    var
        PriceListLineLoop: Record "Price List Line";
        Item: Record Item;
    begin
        PriceListLineLoop.CopyFilters(Rec);
        PriceListLineLoop.SetRange("Price List Code", PriceListCode);

        if PriceListLineLoop.FindSet() then
            repeat
                if (PriceListLineLoop."Asset Type" = PriceListLineLoop."Asset Type"::Item) and
                   Item.Get(PriceListLineLoop."Asset No.") and
                   (Item."COMP Net Price" <> 0) then begin

                    // Save directly to our isolated execution memory map
                    SavePriceToMemory(PriceListLineLoop."Line No.", Item."COMP Net Price");
                end;
            until PriceListLineLoop.Next() = 0;

        CurrPage.Update(false);
    end;

    // Publish changes to price list.
    procedure UpdateActualPriceList(PriceListCode: Code[20])
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        ActualPriceListLine: Record "Price List Line";
        DuplicatePriceLine: Record "Duplicate Price Line";
        PriceListManagement: Codeunit "Price List Management";
        Item: Record Item;
        OriginalStatus: Enum "Price Status";
        PublishMessage: Label 'Price lines successfully published.';
        LineNo: Integer;
        StagedPrice: Decimal;
    begin
        foreach LineNo in StagedPricesMap.Keys() do begin
            StagedPricesMap.Get(LineNo, StagedPrice);
            if StagedPrice <> 0 then begin
                if ActualPriceListLine.Get(PriceListCode, LineNo) then begin
                    ActualPriceListLine.Validate("Unit Price", StagedPrice);
                    ActualPriceListLine.Modify(true);

                    // Update Item Card if applicable
                    if (ActualPriceListLine."Asset Type" = ActualPriceListLine."Asset Type"::Item) and (ActualPriceListLine."Asset No." <> '') then begin
                        if Item.Get(ActualPriceListLine."Asset No.") then begin
                            Item.Validate("Unit Price", StagedPrice);
                            Item.Modify(true);
                        end;
                    end;
                end;
            end;
        end;

        if PriceListHeader.Get(PriceListCode) then begin
            OriginalStatus := PriceListHeader.Status;

            // Set Pricelist to Draft if necessary.
            if PriceListHeader.Status = PriceListHeader.Status::Active then begin
                PriceListHeader.Status := PriceListHeader.Status::Draft;
                PriceListHeader.Modify(false);
            end;

            // Remove blanks.
            PriceListLine.SetRange("Price List Code", PriceListCode);
            PriceListLine.SetRange("Asset No.", '');
            if not PriceListLine.IsEmpty() then
                PriceListLine.DeleteAll(false);

            PriceListLine.Reset();
            PriceListLine.SetRange("Price List Code", PriceListCode);
            PriceListLine.SetRange(Status, PriceListLine.Status::Draft);

            // Remove duplicates.
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

            // Reactivate lines.
            PriceListManagement.ActivateDraftLines(PriceListHeader, true);

            // Reactivate price list.
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

            Message(PublishMessage, PriceListCode);
            CurrPage.Update(false);
        end;
    end;


    local procedure SavePriceToMemory(LineNo: Integer; Price: Decimal)
    begin
        if StagedPricesMap.ContainsKey(LineNo) then
            StagedPricesMap.Set(LineNo, Price)
        else
            StagedPricesMap.Add(LineNo, Price);
    end;

    local procedure TryGetPriceFromMemory(LineNo: Integer; var Price: Decimal): Boolean
    begin
        exit(StagedPricesMap.Get(LineNo, Price));
    end;
}
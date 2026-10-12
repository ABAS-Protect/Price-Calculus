/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-02
    Description: Calculate work sheet lines, update Price List lines.
*/

page 50105 "Worksheet Price Lines Subpart"
{
    PageType = ListPart;
    SourceTable = "Price List Line";
    SourceTableTemporary = true;
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

    actions
    {
        area(Processing)
        {
            action(CopyRowSalesPrice)
            {
                ApplicationArea = All;
                Caption = 'Sales Price ➡️ Unit Price';
                Image = CopyFromTask;
                Scope = Repeater;

                trigger OnAction()
                begin
                    Rec.Validate("Unit Price", ItemSalesPrice);
                    Rec.Modify();
                end;
            }

            action(CopyRowNetPrice)
            {
                ApplicationArea = All;
                Caption = 'Net Price ➡️ Unit Price';
                Image = CopyFromTask;
                Scope = Repeater;

                trigger OnAction()
                begin
                    Rec.Validate("Unit Price", ItemNetPrice);
                    Rec.Modify();
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

    // Calculate difference between calculated and actual price, using sales or net price.
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

    // Baseline sales/net price for difference comparisons.
    procedure SetComparisonBaseline(NewBaseline: Option "Sales Price","Net Price")
    begin
        CurrentBaseline := NewBaseline;
        CurrPage.Update(false);
    end;

    // Copy calculated sales price to price list unit price (worksheet only).
    procedure CopySalesPriceToUnitPrice(PriceListCode: Code[20])
    var
        Item: Record Item;
    begin
        Rec.Reset();
        if Rec.FindSet(true) then
            repeat
                if (Rec."Asset Type" = Rec."Asset Type"::Item) and
                   Item.Get(Rec."Asset No.") and
                   (Item."COMP Sales Price" <> 0) then begin

                    Rec.Validate("Unit Price", Item."COMP Sales Price");
                    Rec.Modify();
                end;
            until Rec.Next() = 0;

        CurrPage.Update(false);
    end;

    // Copy calculated net price to price list unit price (worksheet only).
    procedure CopyNetPriceToUnitPrice(PriceListCode: Code[20])
    var
        Item: Record Item;
    begin
        Rec.Reset();
        if Rec.FindSet(true) then
            repeat
                if (Rec."Asset Type" = Rec."Asset Type"::Item) and
                   Item.Get(Rec."Asset No.") and
                   (Item."COMP Net Price" <> 0) then begin

                    Rec.Validate("Unit Price", Item."COMP Net Price");
                    Rec.Modify();
                end;
            until Rec.Next() = 0;

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
    begin
        Rec.Reset();
        if Rec.FindSet() then
            repeat
                if ActualPriceListLine.Get(Rec."Price List Code", Rec."Line No.") then begin
                    // Update Price List Unit Price.
                    ActualPriceListLine.Validate("Unit Price", Rec."Unit Price");
                    ActualPriceListLine.Modify(true);

                    // Update Item Card Unit Price accordingly.
                    if (Rec."Asset Type" = Rec."Asset Type"::Item) and (Rec."Asset No." <> '') then begin
                        if Item.Get(Rec."Asset No.") then begin
                            Item.Validate("Unit Price", Rec."Unit Price");
                            Item.Modify(true);
                        end;
                    end;
                end;
            until Rec.Next() = 0;

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
            LoadLines(PriceListCode);
        end;
    end;

    // Actual pricelist lines, rather than temp table.
    procedure LoadLines(PriceListCode: Code[20])
    var
        ActualPriceListLine: Record "Price List Line";
    begin
        Rec.Reset();
        Rec.DeleteAll();

        if PriceListCode = '' then
            exit;

        ActualPriceListLine.SetRange("Price List Code", PriceListCode);
        if ActualPriceListLine.FindSet() then
            repeat
                Rec.Copy(ActualPriceListLine);
                Rec.Insert();
            until ActualPriceListLine.Next() = 0;

        if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;
}
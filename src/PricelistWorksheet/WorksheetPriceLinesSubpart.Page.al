/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-02
    Description: Calculate work sheet lines, update Price List lines.
*/

namespace ABAS.ABAS_Price_Calculus;

using Microsoft.Inventory.Item;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Worksheet;

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

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Price list description.';
                    Editable = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Price list variant code.';
                    Editable = false;
                }
                field(ItemReplenishmentSystem; this.ItemReplenishmentSystem)
                {
                    ApplicationArea = All;
                    ToolTip = 'Price list item variant.';
                    Caption = 'Replenishment System';
                    Editable = false;
                    StyleExpr = this.CostStyle;
                }

                field(ItemCost; this.ItemCost)
                {
                    ApplicationArea = All;
                    ToolTip = 'Item cost.';
                    Caption = 'Cost';
                    Editable = false;
                    StyleExpr = this.CostStyle;
                }

                field("COMP Markup Category"; this.MarkupCategoryCode)
                {
                    ApplicationArea = All;
                    ToolTip = 'Price list markup category.';
                    Caption = 'Markup Category';
                    TableRelation = "COMP Markup Category";
                    Lookup = true; // Remove auto-suggest.

                    trigger OnValidate()
                    var
                        Item: Record Item;
                    begin
                        if Item.Get(Rec."Asset No.") then begin
                            Item.Validate("COMP Markup Category", this.MarkupCategoryCode);
                            Item.Modify(true);
                        end;

                        CurrPage.Update(false);
                    end;
                }

                field(ItemMarkup; this.ItemMarkup)
                {
                    ApplicationArea = All;
                    ToolTip = 'Price list item markup.';
                    Caption = 'Overhead Markup %';
                    Editable = this.IsItemAsset;

                    trigger OnValidate()
                    var
                        Item: Record Item;
                    begin
                        if this.IsItemAsset and Item.Get(Rec."Asset No.") then begin
                            Item.Validate("COMP Markup", this.ItemMarkup);
                            Item.Modify(true);

                            this.ItemSalesPrice := Item."COMP Sales Price";
                            this.ItemNetPrice := Item."COMP Net Price";
                            this.CalculateDifferences();

                            CurrPage.Update(false);
                        end;
                    end;
                }

                field(ItemSalesPrice; this.ItemSalesPrice)
                {
                    ApplicationArea = All;
                    ToolTip = 'Price list calculated sales price.';
                    Caption = 'Sales Price (Calc.)';
                    Editable = false;
                    Visible = this.SalesPriceVisible;
                }

                field(ItemNetPrice; this.ItemNetPrice)
                {
                    ApplicationArea = All;
                    ToolTip = 'Price list calculated net price.';
                    Caption = 'Net Price (Calc.)';
                    Editable = false;
                    Visible = this.NetPriceVisible;
                }

                field(ItemComment; this.ItemComment)
                {
                    ApplicationArea = All;
                    ToolTip = 'Price list comment.';
                    Caption = 'Comment';

                    trigger OnValidate()
                    var
                        Item: Record Item;
                    begin
                        if this.IsItemAsset and Item.Get(Rec."Asset No.") then begin
                            Item."COMP Comment" := this.ItemComment;
                            Item.Modify(true);

                            CurrPage.Update(false);
                        end;
                    end;
                }

                field(WorkingUnitPrice; this.WorkingUnitPrice)
                {
                    ApplicationArea = All;
                    ToolTip = 'Price list working unit price.';
                    Caption = 'New Unit Price (Draft)';
                    Editable = true;

                    trigger OnValidate()
                    begin
                        this.SavePriceToMemory(Rec."Line No.", this.WorkingUnitPrice);
                        this.CalculateDifferences();
                        CurrPage.Update(false);
                    end;
                }

                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(PriceDifference; this.PriceDifference)
                {
                    ApplicationArea = All;
                    ToolTip = 'Price list price difference between actual and calculated prices.';
                    Caption = 'Diff.';
                    Editable = false;
                    StyleExpr = this.DifferenceStyle;
                }
                field(PriceDifferencePct; this.PriceDifferencePct)
                {
                    ApplicationArea = All;
                    ToolTip = 'Price list percentage difference between actual and calculated prices.';
                    Caption = 'Diff. (%)';
                    Editable = false;
                    StyleExpr = this.DifferenceStyle;
                }
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
                ToolTip = 'Copy calculated sales price to price list unit price, row only';
                Caption = 'Sales Price ➡️ Unit Price';
                Image = CopyFromTask;
                Scope = Repeater;
                Visible = this.SalesPriceVisible;

                trigger OnAction()
                begin
                    if this.ItemSalesPrice <> 0 then begin
                        this.WorkingUnitPrice := this.ItemSalesPrice;
                        this.SavePriceToMemory(Rec."Line No.", this.WorkingUnitPrice);
                        this.CalculateDifferences();
                    end;
                end;
            }

            // Copy calculated net price to price list unit price, row only.
            action(CopyRowNetPrice)
            {
                ApplicationArea = All;
                ToolTip = 'Copy calculated net price to price list unit price, row only';
                Caption = 'Net Price ➡️ Unit Price';
                Image = CopyFromTask;
                Scope = Repeater;
                Visible = this.NetPriceVisible;

                trigger OnAction()
                begin
                    if this.ItemNetPrice <> 0 then begin
                        this.WorkingUnitPrice := this.ItemNetPrice;
                        this.SavePriceToMemory(Rec."Line No.", this.WorkingUnitPrice);
                        this.CalculateDifferences();
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
        SalesPriceVisible: Boolean;
        NetPriceVisible: Boolean;
        StagedPricesMap: Dictionary of [Integer, Decimal];
        ItemCost: Decimal;
        ItemReplenishmentSystem: Enum "Replenishment System";
        CostStyle: Text;
        MarkupCategoryCode: Code[20];

    trigger OnAfterGetRecord()
    var
        Item: Record Item;
    begin
        this.ClearFields();

        if not this.TryGetPriceFromMemory(Rec."Line No.", this.WorkingUnitPrice) then
            this.WorkingUnitPrice := Rec."Unit Price";

        this.EvaluateLayoutVisibility();

        if (Rec."Price List Code" = '') or (Rec."Asset No." = '') then
            exit;

        this.IsItemAsset := Rec."Asset Type" = Rec."Asset Type"::Item;
        if this.IsItemAsset and Item.Get(Rec."Asset No.") then begin
            this.ItemMarkup := Item."COMP Markup";
            this.ItemSalesPrice := Item."COMP Sales Price";
            this.ItemNetPrice := Item."COMP Net Price";
            this.ItemComment := Item."COMP Comment";
            this.MarkupCategoryCode := Item."COMP Markup Category";

            this.ItemReplenishmentSystem := Item."Replenishment System";
            case Item."Replenishment System" of
                Item."Replenishment System"::Purchase:
                    this.ItemCost := Item."Unit Cost";
                Item."Replenishment System"::"Prod. Order", Item."Replenishment System"::Assembly:
                    this.ItemCost := Item."Standard Cost";
                else
                    this.ItemCost := 0;
            end;

            if (this.ItemCost = 0) or (this.ItemReplenishmentSystem = this.ItemReplenishmentSystem::" ") then
                this.CostStyle := 'Unfavorable'
            else
                this.CostStyle := 'None';

            this.CalculateDifferences();
        end;
    end;

    local procedure ClearFields()
    begin
        this.ItemMarkup := 0;
        this.ItemSalesPrice := 0;
        this.ItemNetPrice := 0;
        this.PriceDifference := 0;
        this.PriceDifferencePct := 0;
        this.IsItemAsset := false;
        this.DifferenceStyle := 'None';
        this.ItemCost := 0;
        Clear(this.ItemReplenishmentSystem);
        Clear(this.MarkupCategoryCode);
        this.CostStyle := 'None';
    end;

    local procedure EvaluateLayoutVisibility()
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

    // Calculate difference between calculated and actual price, using sales or net price.
    local procedure CalculateDifferences()
    var
        TargetBaselinePrice: Decimal;
    begin
        if this.NetPriceVisible then
            TargetBaselinePrice := this.ItemNetPrice
        else
            TargetBaselinePrice := this.ItemSalesPrice;

        if (this.WorkingUnitPrice <> 0) and (TargetBaselinePrice <> 0) then begin
            this.PriceDifference := this.WorkingUnitPrice - TargetBaselinePrice;
            this.PriceDifferencePct := (this.PriceDifference / TargetBaselinePrice) * 100;
        end else begin
            this.PriceDifference := 0;
            this.PriceDifferencePct := 0;
        end;

        if this.PriceDifference > 0 then
            this.DifferenceStyle := 'Favorable'
        else
            if this.PriceDifference < 0 then
                this.DifferenceStyle := 'Unfavorable'
            else
                this.DifferenceStyle := 'None';
    end;

    // Baseline sales/net price for difference comparisons.
    procedure SetComparisonBaseline(NewBaseline: Option "Sales Price","Net Price")
    begin
        this.CurrentBaseline := NewBaseline;
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
                   (Item."COMP Sales Price" <> 0) then
                    this.SavePriceToMemory(PriceListLineLoop."Line No.", Item."COMP Sales Price");
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
                   (Item."COMP Net Price" <> 0) then
                    this.SavePriceToMemory(PriceListLineLoop."Line No.", Item."COMP Net Price");
            until PriceListLineLoop.Next() = 0;

        CurrPage.Update(false);
    end;

    // Publish changes to price list.
    procedure UpdateActualPriceList(PriceListCode: Code[20])
    var
        PublishMsg: Label 'Price lines successfully published.';
    begin
        if PriceListCode = '' then
            exit;

        this.ExecutePriceUpdate(PriceListCode);

        Clear(this.StagedPricesMap);
        Clear(this.WorkingUnitPrice);

        this.CleanUpShadowPriceLists();

        Message(PublishMsg);
        CurrPage.Update(false);
    end;

    local procedure ExecutePriceUpdate(PriceListCode: Code[20])
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        ActualPriceListLine: Record "Price List Line";
        TempPriceListLine: Record "Price Worksheet Line" temporary;
        TempDuplicatePriceLine: Record "Duplicate Price Line";
        PriceListManagement: Codeunit "Price List Management";
        LineNo: Integer;
        StagedPrice: Decimal;
    begin
        if PriceListCode = '' then
            exit;

        if not PriceListHeader.Get(PriceListCode) then
            exit;

        foreach LineNo in this.StagedPricesMap.Keys() do begin
            this.StagedPricesMap.Get(LineNo, StagedPrice);
            if StagedPrice <> 0 then
                if PriceListLine.Get(PriceListCode, LineNo) then begin
                    TempPriceListLine.Init();
                    TempPriceListLine.TransferFields(PriceListLine);
                    TempPriceListLine."Unit Price" := StagedPrice;
                    TempPriceListLine.Status := TempPriceListLine.Status::Draft;
                    TempPriceListLine.Insert();
                end;
        end;

        // Clean up empty configurations
        PriceListLine.Reset();
        PriceListLine.SetRange("Price List Code", PriceListCode);
        PriceListLine.SetRange("Asset No.", '');
        if not PriceListLine.IsEmpty() then
            PriceListLine.DeleteAll(true);

        // Filter out duplicates
        PriceListLine.Reset();
        PriceListLine.SetRange("Price List Code", PriceListCode);
        if PriceListManagement.FindDuplicatePrices(PriceListHeader, PriceListLine, true, TempDuplicatePriceLine) then begin
            TempDuplicatePriceLine.Reset();
            TempDuplicatePriceLine.SetRange("Price List Code", PriceListCode);
            TempDuplicatePriceLine.SetRange(Remove, true);

            if TempDuplicatePriceLine.FindSet() then
                repeat
                    if PriceListLine.Get(TempDuplicatePriceLine."Price List Code", TempDuplicatePriceLine."Line No.") then
                        PriceListLine.Delete(true);
                until TempDuplicatePriceLine.Next() = 0;
        end;

        TempPriceListLine.Reset();
        if TempPriceListLine.FindSet() then
            repeat
                if ActualPriceListLine.Get(TempPriceListLine."Price List Code", TempPriceListLine."Line No.") then begin
                    ActualPriceListLine.Validate("Unit Price", TempPriceListLine."Unit Price");
                    ActualPriceListLine.Status := ActualPriceListLine.Status::Draft;
                    ActualPriceListLine.Modify(false);
                end;
            until TempPriceListLine.Next() = 0;

        PriceListLine.Reset();
        PriceListLine.SetRange("Price List Code", PriceListCode);
        PriceListLine.SetRange(Status, PriceListLine.Status::Draft);
        if PriceListLine.FindSet() then
            repeat
                PriceListManagement.VerifyLines(PriceListLine);
            until PriceListLine.Next() = 0;

        PriceListLine.Reset();
        PriceListLine.SetRange("Price List Code", PriceListCode);
        if not PriceListLine.IsEmpty() then
            PriceListLine.ModifyAll(Status, PriceListLine.Status::Active, false);

        PriceListHeader.Get(PriceListCode);
        PriceListManagement.ActivateDraftLines(PriceListHeader, false);
    end;

    local procedure SavePriceToMemory(LineNo: Integer; NewUnitPrice: Decimal)
    begin
        if this.StagedPricesMap.ContainsKey(LineNo) then
            this.StagedPricesMap.Set(LineNo, NewUnitPrice)
        else
            this.StagedPricesMap.Add(LineNo, NewUnitPrice);
    end;

    local procedure TryGetPriceFromMemory(LineNo: Integer; var StagedUnitPrice: Decimal): Boolean
    begin
        if this.StagedPricesMap.ContainsKey(LineNo) then begin
            StagedUnitPrice := this.StagedPricesMap.Get(LineNo);
            exit(true);
        end;
        exit(false);
    end;

    procedure ClearStagedPrices()
    begin
        Clear(this.StagedPricesMap);
        Clear(this.WorkingUnitPrice);
        CurrPage.Update(false);
    end;

    // Clear out lingering journal lists
    local procedure CleanUpShadowPriceLists()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        PriceListHeader.SetFilter(Code, 'J*');

        if PriceListHeader.FindSet() then
            repeat
                if PriceListHeader.Status = PriceListHeader.Status::Active then begin
                    PriceListHeader.Status := PriceListHeader.Status::Draft;
                    PriceListHeader.Modify(false);
                end;

                PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
                if not PriceListLine.IsEmpty() then
                    PriceListLine.DeleteAll(true);

                PriceListHeader.Delete(true);
            until PriceListHeader.Next() = 0;
    end;
}
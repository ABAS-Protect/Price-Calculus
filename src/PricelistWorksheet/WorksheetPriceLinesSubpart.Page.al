/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-02
    Description: Calculate work sheet lines, update Price List lines.
*/

namespace ABAS.ABAS_Price_Calculus;

using Microsoft.Inventory.Item;
using Microsoft.Pricing.PriceList;

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
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        ActualPriceListLine: Record "Price List Line";
        TempDuplicatePriceLine: Record "Duplicate Price Line";
        PriceListManagement: Codeunit "Price List Management";
        OriginalStatus: Enum "Price Status";
        PublishMsg: Label 'Price lines successfully published.';
        LineNo: Integer;
        StagedPrice: Decimal;
    begin
        if PriceListCode = '' then
            exit;

        ActualPriceListLine.LockTable();

        foreach LineNo in this.StagedPricesMap.Keys() do begin
            this.StagedPricesMap.Get(LineNo, StagedPrice);
            if StagedPrice <> 0 then begin
                ActualPriceListLine.SetRange("Price List Code", PriceListCode);
                ActualPriceListLine.SetRange("Line No.", LineNo);
                if ActualPriceListLine.Get(PriceListCode, LineNo) then begin
                    ActualPriceListLine.Validate("Unit Price", StagedPrice);
                    ActualPriceListLine.Modify(true);

                    // Update Item Card if applicable
                    if (ActualPriceListLine."Asset Type" = ActualPriceListLine."Asset Type"::Item) and (ActualPriceListLine."Asset No." <> '') then
                        if Item.Get(ActualPriceListLine."Asset No.") then begin
                            Item.Validate("Unit Price", StagedPrice);
                            Item.Modify(true);
                        end;
                end;
            end;
        end;

        Clear(this.StagedPricesMap);
        Clear(this.WorkingUnitPrice);

        if PriceListHeader.Get(PriceListCode) then begin
            OriginalStatus := PriceListHeader.Status;

            // Set Pricelist to Draft if necessary.
            if PriceListHeader.Status = PriceListHeader.Status::Active then begin
                PriceListHeader.Status := PriceListHeader.Status::Draft;
                PriceListHeader.Modify(true);
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
            if PriceListManagement.FindDuplicatePrices(PriceListHeader, PriceListLine, true, TempDuplicatePriceLine) then begin
                TempDuplicatePriceLine.Reset();
                TempDuplicatePriceLine.SetRange("Price List Code", PriceListCode);
                TempDuplicatePriceLine.SetRange(Remove, true);

                if TempDuplicatePriceLine.FindSet() then
                    repeat
                        if PriceListLine.Get(TempDuplicatePriceLine."Price List Code", TempDuplicatePriceLine."Line No.") then
                            PriceListLine.Delete(false);
                    until TempDuplicatePriceLine.Next() = 0;
            end;

            // Reactivate lines.
            PriceListHeader.Get(PriceListCode);
            PriceListManagement.ActivateDraftLines(PriceListHeader, true);

            if OriginalStatus = OriginalStatus::Active then begin
                PriceListHeader.Get(PriceListCode);
                PriceListHeader.Status := PriceListHeader.Status::Active;
                PriceListHeader.Modify(true);

                PriceListLine.Reset();
                PriceListLine.SetRange("Price List Code", PriceListCode);
                PriceListLine.SetRange(Status, PriceListLine.Status::Draft);
                if not PriceListLine.IsEmpty() then
                    PriceListLine.ModifyAll(Status, PriceListLine.Status::Active, true);
            end else
                if PriceListHeader.Status <> OriginalStatus then begin
                    PriceListHeader.Status := OriginalStatus;
                    PriceListHeader.Modify(true);
                end;

            Message(PublishMsg);

            Clear(this.StagedPricesMap);
            Clear(this.WorkingUnitPrice);
            CurrPage.Update(false);
        end;
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
}
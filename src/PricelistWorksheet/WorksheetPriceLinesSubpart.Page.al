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
                    Lookup = true; // Remove auto-suggest.

                    trigger OnValidate()
                    var
                        Item: Record Item;
                    begin
                        this.InvalidateItemCache(Rec."Asset No.");

                        if Item.Get(Rec."Asset No.") then begin
                            Item.Validate("COMP Markup Category", this.MarkupCategoryCode);
                            Item.Modify(true);
                        end;

                        this.RefreshVisibleRowsForItem(Rec."Asset No.");
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
                        if this.IsItemAsset then begin
                            this.InvalidateItemCache(Rec."Asset No.");

                            if Item.Get(Rec."Asset No.") then begin
                                Item.Validate("COMP Markup", this.ItemMarkup);
                                Item.Modify(true);

                                this.ItemSalesPrice := Item."COMP Sales Price";
                                this.ItemNetPrice := Item."COMP Net Price";
                                this.CalculateDifferences();
                            end;

                            this.RefreshVisibleRowsForItem(Rec."Asset No.");
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
                        if this.IsItemAsset then begin
                            this.InvalidateItemCache(Rec."Asset No.");

                            if Item.Get(Rec."Asset No.") then begin
                                Item."COMP Comment" := this.ItemComment;
                                Item.Modify(true);
                            end;

                            this.RefreshVisibleRowsForItem(Rec."Asset No.");
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
        ItemCostCache: Dictionary of [Code[20], Decimal];
        ItemReplSystemCache: Dictionary of [Code[20], Enum "Replenishment System"];
        ItemMarkupCache: Dictionary of [Code[20], Integer];
        ItemSalesPriceCache: Dictionary of [Code[20], Decimal];
        ItemNetPriceCache: Dictionary of [Code[20], Decimal];
        ItemCommentCache: Dictionary of [Code[20], Text[100]];
        ItemMarkupCatCache: Dictionary of [Code[20], Code[20]];
        ItemCost: Decimal;
        ItemReplenishmentSystem: Enum "Replenishment System";
        CostStyle: Text;
        MarkupCategoryCode: Code[20];

    trigger OnAfterGetRecord()
    begin
        this.ClearFields();

        if not this.TryGetPriceFromMemory(Rec."Line No.", this.WorkingUnitPrice) then
            this.WorkingUnitPrice := Rec."Unit Price";

        this.EvaluateLayoutVisibility();

        if (Rec."Price List Code" = '') or (Rec."Asset No." = '') then
            exit;

        this.IsItemAsset := Rec."Asset Type" = Rec."Asset Type"::Item;
        if this.IsItemAsset then begin
            this.FetchItemDetailsCached(Rec."Asset No.");
            this.CalculateDifferences();
        end;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        this.ClearCache();
        exit(Rec.Find(Which));
    end;

    local procedure ClearCache()
    begin
        Clear(this.ItemCostCache);
        Clear(this.ItemReplSystemCache);
        Clear(this.ItemMarkupCache);
        Clear(this.ItemSalesPriceCache);
        Clear(this.ItemNetPriceCache);
        Clear(this.ItemCommentCache);
        Clear(this.ItemMarkupCatCache);
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

    local procedure FetchItemDetailsCached(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        if this.ItemCostCache.ContainsKey(ItemNo) then begin
            this.ItemCostCache.Get(ItemNo, this.ItemCost);
            this.ItemReplSystemCache.Get(ItemNo, this.ItemReplenishmentSystem);
            this.ItemMarkupCache.Get(ItemNo, this.ItemMarkup);
            this.ItemSalesPriceCache.Get(ItemNo, this.ItemSalesPrice);
            this.ItemNetPriceCache.Get(ItemNo, this.ItemNetPrice);
            this.ItemCommentCache.Get(ItemNo, this.ItemComment);
            this.ItemMarkupCatCache.Get(ItemNo, this.MarkupCategoryCode);
        end else
            if Item.Get(ItemNo) then begin
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

                this.ItemCostCache.Add(ItemNo, this.ItemCost);
                this.ItemReplSystemCache.Add(ItemNo, this.ItemReplenishmentSystem);
                this.ItemMarkupCache.Add(ItemNo, this.ItemMarkup);
                this.ItemSalesPriceCache.Add(ItemNo, this.ItemSalesPrice);
                this.ItemNetPriceCache.Add(ItemNo, this.ItemNetPrice);
                this.ItemCommentCache.Add(ItemNo, this.ItemComment);
                this.ItemMarkupCatCache.Add(ItemNo, this.MarkupCategoryCode);
            end;

        if (this.ItemCost = 0) or (this.ItemReplenishmentSystem = this.ItemReplenishmentSystem::" ") then
            this.CostStyle := 'Unfavorable'
        else
            this.CostStyle := 'None';
    end;

    local procedure InvalidateItemCache(ItemNo: Code[20])
    begin
        if ItemNo = '' then
            exit;

        if this.ItemCostCache.ContainsKey(ItemNo) then this.ItemCostCache.Remove(ItemNo);
        if this.ItemReplSystemCache.ContainsKey(ItemNo) then this.ItemReplSystemCache.Remove(ItemNo);
        if this.ItemMarkupCache.ContainsKey(ItemNo) then this.ItemMarkupCache.Remove(ItemNo);
        if this.ItemSalesPriceCache.ContainsKey(ItemNo) then this.ItemSalesPriceCache.Remove(ItemNo);
        if this.ItemNetPriceCache.ContainsKey(ItemNo) then this.ItemNetPriceCache.Remove(ItemNo);
        if this.ItemCommentCache.ContainsKey(ItemNo) then this.ItemCommentCache.Remove(ItemNo);
        if this.ItemMarkupCatCache.ContainsKey(ItemNo) then this.ItemMarkupCatCache.Remove(ItemNo);
    end;

    local procedure RefreshVisibleRowsForItem(TargetItemNo: Code[20])
    var
        PriceListLineBuffer: Record "Price List Line";
    begin
        if TargetItemNo = '' then
            exit;

        this.InvalidateItemCache(TargetItemNo);

        PriceListLineBuffer.Copy(Rec);

        Rec.Reset();
        Rec.CopyFilters(PriceListLineBuffer);
        Rec.SetRange("Asset Type", Rec."Asset Type"::Item);
        Rec.SetRange("Asset No.", TargetItemNo);

        if Rec.FindSet() then
            repeat
                this.ClearFields();
                if not this.TryGetPriceFromMemory(Rec."Line No.", this.WorkingUnitPrice) then
                    this.WorkingUnitPrice := Rec."Unit Price";

                this.EvaluateLayoutVisibility();
                this.FetchItemDetailsCached(Rec."Asset No.");
                this.CalculateDifferences();
            until Rec.Next() = 0;

        Rec.Copy(PriceListLineBuffer);
        CurrPage.Update(false);
    end;

    local procedure ExecutePriceUpdate(PriceListCode: Code[20])
    var
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        ActualPriceListLine: Record "Price List Line";
        TempDuplicatePriceLine: Record "Duplicate Price Line";
        PriceListManagement: Codeunit "Price List Management";
        OriginalStatus: Enum "Price Status";
        LineNo: Integer;
        StagedPrice: Decimal;
    begin
        if PriceListCode = '' then
            exit;

        if not PriceListHeader.Get(PriceListCode) then
            exit;

        OriginalStatus := PriceListHeader.Status;

        if PriceListHeader.Status = PriceListHeader.Status::Active then begin
            PriceListHeader.Status := PriceListHeader.Status::Draft;
            PriceListHeader.Modify(false);
        end;

        foreach LineNo in this.StagedPricesMap.Keys() do begin
            this.StagedPricesMap.Get(LineNo, StagedPrice);
            if StagedPrice <> 0 then
                if ActualPriceListLine.Get(PriceListCode, LineNo) then begin
                    ActualPriceListLine.Validate("Unit Price", StagedPrice);
                    ActualPriceListLine.Status := ActualPriceListLine.Status::Draft;
                    ActualPriceListLine.Modify(false);
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

        if OriginalStatus = OriginalStatus::Active then
            if PriceListHeader.Get(PriceListCode) then begin
                PriceListHeader.Status := PriceListHeader.Status::Active;
                PriceListHeader.Modify(false);
            end;

        foreach LineNo in this.StagedPricesMap.Keys() do begin
            this.StagedPricesMap.Get(LineNo, StagedPrice);
            if (StagedPrice <> 0) and ActualPriceListLine.Get(PriceListCode, LineNo) then
                if (ActualPriceListLine."Asset Type" = ActualPriceListLine."Asset Type"::Item) and (ActualPriceListLine."Asset No." <> '') then
                    if Item.Get(ActualPriceListLine."Asset No.") then begin
                        Item.Validate("Unit Price", StagedPrice);
                        Item.Modify(true);
                    end;
        end;
    end;

    procedure ClearStagedPrices()
    begin
        Clear(this.StagedPricesMap);
        this.ClearCache();
        Clear(this.WorkingUnitPrice);
        CurrPage.Update(false);
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
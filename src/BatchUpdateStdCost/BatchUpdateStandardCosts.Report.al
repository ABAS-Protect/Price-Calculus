/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-01
    Description: Batch calculate Standard Cost and add to Item Card. Run as a nightly cron job.
*/

namespace ABAS.ABAS_Price_Calculus;

using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.StandardCost;

report 50101 BatchUpdateStandardCosts
{
    UsageCategory = Tasks;
    ApplicationArea = All;
    ProcessingOnly = true;
    Caption = 'ABAS Update Item Standard Costs (Prod/Assembly)';

    dataset
    {
        dataitem(Item; Item)
        {
            RequestFilterFields = "No.", "Item Category Code";

            // Collect non-blocked items with production order or assembly replenishment system.
            trigger OnPreDataItem()
            begin
                Item.SetFilter("Replenishment System", '%1|%2',
                    Enum::"Replenishment System"::"Prod. Order",
                    Enum::"Replenishment System"::Assembly);

                Item.SetRange(Blocked, false);

                if GuiAllowed then
                    this.Window.Open('Collecting items...\#1####################');
            end;

            // Collect item numbers to be calculated.
            trigger OnAfterGetRecord()
            var
                ProdBOMHeader: Record "Production BOM Header";
                BOMComponent: Record "BOM Component";
            begin
                // Skip SKUs with empty or uncertified BOM headers and non-existing assembly BOMs.
                if Item."Replenishment System" = Enum::"Replenishment System"::"Prod. Order" then begin
                    if Item."Production BOM No." = '' then
                        CurrReport.Skip();

                    if not this.TryCheckBomHeader(Item."Production BOM No.") then begin
                        ClearLastError();
                        CurrReport.Skip();
                    end;

                    if ProdBOMHeader.Get(Item."Production BOM No.") then begin
                        if ProdBOMHeader.Status <> ProdBOMHeader.Status::Certified then
                            CurrReport.Skip();
                    end else
                        CurrReport.Skip();
                end;

                if Item."Replenishment System" = Enum::"Replenishment System"::Assembly then begin
                    BOMComponent.SetRange("Parent Item No.", Item."No.");
                    if BOMComponent.IsEmpty() then
                        CurrReport.Skip();
                end;

                if GuiAllowed then
                    this.Window.Update(1, Item."No.");

                this.ItemNoCollection.Add(Item."No.");
            end;

            // Calculate standard cost for each item number in collected list.
            trigger OnPostDataItem()
            var
                TargetItem: Code[20];
            begin
                if GuiAllowed then
                    this.Window.Open('Processing...\#1####################');

                foreach TargetItem in this.ItemNoCollection do begin
                    if GuiAllowed then
                        this.Window.Update(1, TargetItem);

                    this.ExecuteHeadlessTransaction(TargetItem);
                end;

                if GuiAllowed then begin
                    this.Window.Close();
                    Message('Standard costs updated.');
                end;
            end;
        }
    }

    var
        Window: Dialog;
        ItemNoCollection: List of [Code[20]];

    local procedure ExecuteHeadlessTransaction(ItemNo: Code[20])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        TargetItem: Record Item;
        HeadlessStdCostRunner: Codeunit "HeadlessStdCostRunner";
        CalcProdStdCost: Codeunit "Calculate Standard Cost";
    begin
        Clear(HeadlessStdCostRunner);
        HeadlessStdCostRunner.SetItemNo(ItemNo);

        if HeadlessStdCostRunner.Run() then begin
            if TargetItem.Get(ItemNo) then
                // Iterate over SKUs.
                if TargetItem."Replenishment System" = Enum::"Replenishment System"::"Prod. Order" then begin
                    StockkeepingUnit.SetRange("Item No.", ItemNo);
                    if StockkeepingUnit.FindSet() then
                        repeat
                            Clear(CalcProdStdCost);
                            CalcProdStdCost.SetProperties(WorkDate(), true, false, true, '', false);

                            CalcProdStdCost.CalcItemSKU(
                                StockkeepingUnit."Item No.",
                                StockkeepingUnit."Location Code",
                                StockkeepingUnit."Variant Code"
                            );
                        until StockkeepingUnit.Next() = 0;
                end;

            Commit();
        end;
    end;

    [TryFunction]
    local procedure TryCheckBomHeader(BomNo: Code[20])
    var
        ProdBomHeader: Record "Production BOM Header";
    begin
        ProdBomHeader.Get(BomNo);
    end;
}
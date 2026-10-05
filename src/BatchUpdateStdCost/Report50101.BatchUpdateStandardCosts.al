/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-01
    Description: Batch calculate Standard Cost and add to Item Card.
*/

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

            trigger OnPreDataItem()
            begin
                Item.SetFilter("Replenishment System", '%1|%2',
                    Enum::"Replenishment System"::"Prod. Order",
                    Enum::"Replenishment System"::Assembly);

                Item.SetRange(Blocked, false);

                if GuiAllowed then
                    Window.Open('Collecting items...\#1####################');
            end;

            trigger OnAfterGetRecord()
            var
                ProdBOMHeader: Record "Production BOM Header";
                BOMComponent: Record "BOM Component";
            begin
                if Item."Replenishment System" = Enum::"Replenishment System"::"Prod. Order" then begin
                    if Item."Production BOM No." = '' then
                        CurrReport.Skip();

                    if not TryCheckBomHeader(Item."Production BOM No.") then begin
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
                    Window.Update(1, Item."No.");

                ItemNoCollection.Add(Item."No.");
            end;

            trigger OnPostDataItem()
            var
                TargetItem: Code[20];
            begin
                if GuiAllowed then
                    Window.Open('Processing...\#1####################');

                foreach TargetItem in ItemNoCollection do begin
                    if GuiAllowed then
                        Window.Update(1, TargetItem);

                    ExecuteHeadlessTransaction(TargetItem);
                end;

                if GuiAllowed then begin
                    Window.Close();
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
        HeadlessStdCostRunner: Codeunit "HeadlessStdCostRunner";
        CalcProdStdCost: Codeunit "Calculate Standard Cost";
        StockkeepingUnit: Record "Stockkeeping Unit";
        TargetItem: Record Item;
    begin
        Clear(HeadlessStdCostRunner);
        HeadlessStdCostRunner.SetItemNo(ItemNo);

        if HeadlessStdCostRunner.Run() then begin

            if TargetItem.Get(ItemNo) then begin
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
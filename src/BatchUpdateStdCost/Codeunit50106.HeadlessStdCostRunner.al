/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-01
    Description: Calculate Standard Cost isolated from batch (avoid DB error).
*/

codeunit 50106 HeadlessStdCostRunner
{
    var
        GlobalItemNo: Code[20];

    procedure SetItemNo(ItemNo: Code[20])
    begin
        GlobalItemNo := ItemNo;
    end;

    trigger OnRun()
    var
        TargetItem: Record Item;
        CalcProdStdCost: Codeunit "Calculate Standard Cost";
        IsAssembly: Boolean;
    begin
        if not TargetItem.Get(GlobalItemNo) then
            exit;

        Clear(CalcProdStdCost);
        IsAssembly := TargetItem."Replenishment System" = Enum::"Replenishment System"::Assembly;

        CalcProdStdCost.SetProperties(WorkDate(), true, IsAssembly, true, '', false);
        CalcProdStdCost.CalcItem(TargetItem."No.", IsAssembly);
    end;
}
/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-01
    Description: Bypass modal dialog Top Levels / All Levels in Standard Cost calculation.
*/

codeunit 50105 SilenceStdCostDialog
{
    SingleInstance = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calculate Standard Cost", 'OnCalcItemOnBeforeShowStrMenu', '', false, false)]
    local procedure SuppressLevelSelectionMenu(var Item: Record Item; var ShowStrMenu: Boolean; var NewCalcMultiLevel: Boolean)
    begin
        ShowStrMenu := false;
        NewCalcMultiLevel := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calculate Standard Cost", 'OnCalcItemOnAfterCalcShowConfirm', '', false, false)]
    local procedure SuppressAssemblyConfirmMenu(Item: Record Item; var CalcMfgItems: Boolean; var ShowConfirm: Boolean)
    begin
        ShowConfirm := false;
        CalcMfgItems := true;
    end;
}
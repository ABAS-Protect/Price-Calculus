/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-16
    Description: Install page for ABAS price calculus.
*/

namespace ABAS.ABAS_Price_Calculus;

codeunit 50109 "Price Calculus Setup Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        InitializeSetup();
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Price Calculus Setup Table", 'RI')]
    local procedure InitializeSetup()
    var
        PriceCalculusSetup: Record "Price Calculus Setup Table";
    begin
        if not PriceCalculusSetup.Get() then begin
            PriceCalculusSetup.Init();
            PriceCalculusSetup."Primary Key" := '';

            PriceCalculusSetup."Rebate Base %" := 52;
            PriceCalculusSetup."Production Markup %" := 5;
            PriceCalculusSetup."Purchase Markup %" := 0;

            PriceCalculusSetup.Insert();
        end;
    end;
}
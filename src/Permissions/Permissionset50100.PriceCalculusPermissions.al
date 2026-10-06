/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-06
    Description: Permission set for ABAS Price Calculus objects.
*/

permissionset 50100 "ABAS Calculus Admin"
{
    Assignable = true;
    Caption = 'ABAS Price Calculus Permissions, Admin Rights';

    Permissions =
        tabledata "Price Calculus Setup Table" = RIMD,
        tabledata "Worksheet Header" = RIMD,
        page "ABAS Price Calculus Setup" = X,
        page "ABAS Price List Worksheet" = X,
        page "Worksheet Price Lines Subpart" = X,
        codeunit "Filter Standard Price List" = X,
        codeunit SilenceStdCostDialog = X,
        codeunit HeadlessStdCostRunner = X,
        report BatchUpdateStandardCosts = X,
        report "Check SKU BOM References" = X;
}

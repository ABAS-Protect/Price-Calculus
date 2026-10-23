/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-06
    Description: Permission set for ABAS Price Calculus objects.
*/

namespace ABAS.ABAS_Price_Calculus;

permissionset 50100 "ABAS Calculus Admin"
{
    Assignable = true;
    Caption = 'ABAS Price Calculus Permissions, Admin Rights';

    Permissions =
        tabledata "Price Calculus Setup Table" = RIMD,
        tabledata "Worksheet Header" = RIMD,
        tabledata "COMP Markup Category" = RIMD,
        tabledata "COMP Markup Category Trans" = RIMD,
        tabledata "Price List Print Line" = RIMD,
        tabledata "Price List Group" = RIMD,
        tabledata "Price List Group Translation" = RIMD,
        page "ABAS Price Calculus Setup" = X,
        page "ABAS Price List Worksheet" = X,
        page "Worksheet Price Lines Subpart" = X,
        page "Price List Selection Worksheet" = X,
        page "Price Selection Lines Subpart" = X,
        page "Price Group Translations" = X,
        page "Price List Groups Lookup" = X,
        page "COMP Markup Categories" = X,
        page "COMP Markup Cat. Trans Sub" = X,
        codeunit "Price Calculus Setup Install" = X,
        codeunit "Filter Standard Price List" = X,
        codeunit SilenceStdCostDialog = X,
        codeunit HeadlessStdCostRunner = X,
        codeunit "COMP Markup Init Subscriptions" = X,
        codeunit "Suppress Activation Dialog" = X,
        report BatchUpdateStandardCosts = X,
        report "Check SKU BOM References" = X,
        report "Combined Price List Report" = X;
}

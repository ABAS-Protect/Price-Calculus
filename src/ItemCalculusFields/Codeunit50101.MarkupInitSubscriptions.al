/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-19
    Description: Install Markup Category.
*/

codeunit 50101 "COMP Markup Init Subscriptions"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        MarkupCategory: Record "COMP Markup Category";
    begin
        if not MarkupCategory.Get('STANDARD') then begin
            MarkupCategory.Init();
            MarkupCategory.Code := 'STANDARD';
            MarkupCategory.Description := 'Standard Default Markup';
            MarkupCategory."Markup %" := 70;
            MarkupCategory.Insert();
        end;
    end;
}

/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-19
    Description: Translation page for Markup Category.
*/

page 50111 "COMP Markup Cat. Trans Sub"
{
    PageType = List;
    SourceTable = "COMP Markup Category Trans";
    Caption = 'ABAS Markup Category Translations';

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Language Code"; Rec."Language Code") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }
}
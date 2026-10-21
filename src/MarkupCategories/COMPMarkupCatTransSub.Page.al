/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-19
    Description: Translation page for Markup Category.
*/

namespace ABAS.ABAS_Price_Calculus;

page 50111 "COMP Markup Cat. Trans Sub"
{
    ApplicationArea = All;
    UsageCategory = Lists;
    PageType = List;
    SourceTable = "COMP Markup Category Trans";
    Caption = 'ABAS Markup Category Translations';

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Price Calculus Group Language Code';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Price Calculus Group Code Description';
                }
            }
        }
    }
}
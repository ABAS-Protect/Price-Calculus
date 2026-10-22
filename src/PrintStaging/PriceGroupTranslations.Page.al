/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-22
    Description: Configuration window for recording multi-language group values.
*/

namespace ABAS.ABAS_Price_Calculus;

page 50113 "Price Group Translations"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Price List Group Translation";
    Caption = 'Price Group Translations';

    layout
    {
        area(Content)
        {
            repeater(GroupTranslations)
            {
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select the system language code mapping target.';
                }
                field("Description"; Rec."Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Type the translated text expression to display for users in this locale.';
                }
            }
        }
    }
}
/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-01
    Description: Add fields to Item Card.
*/

namespace ABAS.ABAS_Price_Calculus;

using Microsoft.Inventory.Item;

pageextension 50109 ItemCardCalculusFields extends "Item Card"
{
    layout
    {
        addafter("Unit Price")
        {

            field("COMP Markup Category"; Rec."COMP Markup Category")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the markup category for this item.';

            }
            field("COMP Markup"; Rec."COMP Markup")
            {
                ApplicationArea = All;
                ToolTip = 'Overhead Markup';
                Style = Subordinate;
            }
            field("COMP Sales Price"; Rec."COMP Sales Price")
            {
                ApplicationArea = All;
                ToolTip = 'Calculates Sales Price';
            }
            field("COMP Net Price"; Rec."COMP Net Price")
            {
                ApplicationArea = All;
                ToolTip = 'Calculated Net Price';
            }
            field("COMP Comment"; Rec."COMP Comment")
            {
                ApplicationArea = All;
                ToolTip = 'Price Calculus Comment';
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        MarkupCategory: Record "COMP Markup Category";
    begin
        Clear(CategoryText);
        if Rec."COMP Markup Category" <> '' then
            if MarkupCategory.Get(Rec."COMP Markup Category") then
                CategoryText := MarkupCategory.GetTranslatedDescription();
    end;

    var
        CategoryText: Text;
}
/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-01
    Description: Add fields to Item Card.
*/

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
                Style = Subordinate;
            }
            field("COMP Sales Price"; Rec."COMP Sales Price")
            {
                ApplicationArea = All;
            }
            field("COMP Net Price"; Rec."COMP Net Price")
            {
                ApplicationArea = All;
            }
            field("COMP Comment"; Rec."COMP Comment")
            {
                ApplicationArea = All;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        MarkupCategory: Record "COMP Markup Category";
    begin
        Clear(CategoryText);
        if Rec."COMP Markup Category" <> '' then begin
            if MarkupCategory.Get(Rec."COMP Markup Category") then begin
                CategoryText := MarkupCategory.GetTranslatedDescription();
            end;
        end;
    end;

    var
        CategoryText: Text;
}
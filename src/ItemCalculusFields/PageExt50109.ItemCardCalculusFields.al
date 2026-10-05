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
}
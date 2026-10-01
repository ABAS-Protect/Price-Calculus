pageextension 50109 ItemCardCalculusFields extends "Item Card"
{
    layout
    {
        addafter("Unit Price")
        {
            field("COMP Markup"; Rec."COMP Markup")
            {
                ApplicationArea = All;
                ToolTip = 'Markup';
                Style = Subordinate;
            }
            field("COMP Sales Price"; Rec."COMP Sales Price")
            {
                ApplicationArea = All;
                ToolTip = 'Suggested Sales Price';
            }
            field("COMP Net Price"; Rec."COMP Net Price")
            {
                ApplicationArea = All;
                ToolTip = 'Suggested Net Price';
            }
        }
    }
}
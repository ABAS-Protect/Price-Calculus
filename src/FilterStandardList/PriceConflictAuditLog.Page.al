namespace ABAS.ABAS_Price_Calculus;

using Microsoft.Pricing.PriceList;

page 50114 "Price Conflict Audit Log"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Tasks;
    SourceTable = "Price List Line";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    Caption = 'Price Conflict Audit Log';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Asset No."; Rec."Asset No.")
                {
                    ApplicationArea = All;
                    Caption = 'Item No.';
                    ToolTip = 'Specifies the item identifier.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    Caption = 'Variant Code';
                    ToolTip = 'Specifies the item variant variant.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Conflict Analysis Reason';
                    ToolTip = 'Details why this row conflicts with other pricing configurations.';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = All;
                    Caption = 'Competing Price List';
                    ToolTip = 'Identifies the active external price list housing the conflict rule.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    Caption = 'Current Price';
                }
            }
        }
    }
}
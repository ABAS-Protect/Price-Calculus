/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-06
    Description: Setup page for ABAS price calculus.
*/

page 50107 "ABAS Price Calculus Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Price Calculus Setup Table";
    Caption = 'ABAS Price Calculus Setup';
    InsertAllowed = false;
    DeleteAllowed = false;

    AccessByPermission = TableData "Price Calculus Setup Table" = RM;

    layout
    {
        area(Content)
        {
            group(Calculations)
            {
                Caption = 'Calculation Setup';

                field("Rebate Base %"; Rec."Rebate Base %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the base percentage used for rebate calculations (default 52%).';
                }
                field("Production Markup %"; Rec."Production Markup %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the markup percentage applied to production costs (default 5%).';
                }
                field("Purchase Markup %"; Rec."Purchase Markup %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the markup percentage applied to purchase costs (default 0%).';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec."Primary Key" := '';

            Rec."Rebate Base %" := 52;
            Rec."Production Markup %" := 5;
            Rec."Purchase Markup %" := 0;

            Rec.Insert();
        end;
    end;
}
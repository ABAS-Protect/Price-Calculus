/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-01
    Description: Add price calculus fields to Item Card.
*/

tableextension 50102 ItemsCalculusFields extends Item
{
    fields
    {
        field(50104; "COMP Markup"; Integer)
        {
            Caption = 'Overhead Markup %';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                Rec.CalculateSalesPrice();
            end;
        }
        field(50105; "COMP Sales Price"; Decimal)
        {
            Caption = 'Sales Price (Calc.)';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50106; "COMP Net Price"; Decimal)
        {
            Caption = 'Net Price (Calc.)';
            DataClassification = CustomerContent;
            Editable = false;
        }

        modify("Standard Cost")
        {
            trigger OnAfterValidate()
            begin
                Rec.CalculateSalesPrice();
            end;
        }

        modify("Unit Cost")
        {
            trigger OnAfterValidate()
            begin
                Rec.CalculateSalesPrice();
            end;
        }

        modify("Replenishment System")
        {
            trigger OnAfterValidate()
            begin
                Rec.CalculateSalesPrice();
            end;
        }
    }
    procedure CalculateSalesPrice()
    var
        BaseCost: Decimal;
        PRODUCTION_MARKUP: Decimal;
        REBATE_BASE: DECIMAL;
        REBATE_MARKUP: Decimal;
    begin
        if Rec."COMP Markup" = 0 then begin
            Rec."COMP Sales Price" := 0;
            Rec."COMP Net Price" := 0;
            exit;
        end;

        case Rec."Replenishment System" of
            Rec."Replenishment System"::Purchase:
                begin
                    BaseCost := Rec."Unit Cost";
                    PRODUCTION_MARKUP := 0;
                end;

            Rec."Replenishment System"::"Prod. Order", Rec."Replenishment System"::Assembly:
                begin
                    BaseCost := Rec."Standard Cost";
                    PRODUCTION_MARKUP := 0.05;
                end;

            else
                BaseCost := 0;
        end;

        if BaseCost > 0 then begin
            REBATE_BASE := 0.52;
            REBATE_MARKUP := 1 / (1 - REBATE_BASE);

            Rec."COMP Sales Price" := BaseCost * (1 + (Rec."COMP Markup" / 100) + PRODUCTION_MARKUP) * REBATE_MARKUP;
            Rec."COMP Net Price" := (1 - REBATE_BASE) * Rec."COMP Sales Price";
        end else begin
            Rec."COMP Sales Price" := 0;
            Rec."COMP Net Price" := 0;
        end;
    end;
}

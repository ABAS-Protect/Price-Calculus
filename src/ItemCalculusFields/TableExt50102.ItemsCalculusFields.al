/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-01
    Description: Add fields to Item table.
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

        field(50107; "COMP Comment"; Text[100])
        {
            Caption = 'Comment';
            DataClassification = CustomerContent;
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
        Const: Record "Price Calculus Setup Table";
        BaseCost: Decimal;

        PRODUCTION_MARKUP: Decimal;
        PURCHASE_MARKUP: Decimal;
        REBATE_BASE: Decimal;

        Rebate_Markup: Decimal;
        Markup: Decimal;
        RawNetPrice: Decimal;
        RawSalesPrice: Decimal;
    begin
        if Const.Get() then begin
            PRODUCTION_MARKUP := Const."Production Markup %" / 100;
            PURCHASE_MARKUP := Const."Purchase Markup %" / 100;
            REBATE_BASE := Const."Rebate Base %" / 100;
        end else begin
            PRODUCTION_MARKUP := 0.05;
            PURCHASE_MARKUP := 0.00;
            REBATE_BASE := 0.52;
        end;

        if Rec."COMP Markup" = 0 then begin
            Rec."COMP Sales Price" := 0;
            Rec."COMP Net Price" := 0;
            exit;
        end;

        case Rec."Replenishment System" of
            Rec."Replenishment System"::Purchase:
                begin
                    BaseCost := Rec."Unit Cost";
                    Markup := PURCHASE_MARKUP;
                end;

            Rec."Replenishment System"::"Prod. Order", Rec."Replenishment System"::Assembly:
                begin
                    BaseCost := Rec."Standard Cost";
                    Markup := PRODUCTION_MARKUP;
                end;

            else
                BaseCost := 0;
        end;

        if BaseCost > 0 then begin
            if REBATE_BASE <> 1 then
                Rebate_Markup := 1 / (1 - REBATE_BASE)
            else
                Rebate_Markup := 100;

            RawNetPrice := BaseCost * (1 + (Rec."COMP Markup" / 100) + Markup);
            RawSalesPrice := RawNetPrice * Rebate_Markup;

            Rec."COMP Sales Price" := RoundCalculatedPrice(RawSalesPrice);
            Rec."COMP Net Price" := RoundCalculatedPrice(RawNetPrice);
        end else begin
            Rec."COMP Sales Price" := 0;
            Rec."COMP Net Price" := 0;
        end;
    end;

    local procedure RoundCalculatedPrice(InputPrice: Decimal): Decimal
    begin
        if InputPrice = 0 then
            exit(0);

        if InputPrice < 10 then
            exit(Round(InputPrice, 0.01, '>'));

        if InputPrice < 100 then
            exit(Round(InputPrice, 0.50, '>'));

        exit(Round(InputPrice, 1.00, '>'));
    end;
}

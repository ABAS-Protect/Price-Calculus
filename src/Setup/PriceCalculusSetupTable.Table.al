/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-06
    Description: Table data for setup page.
*/

namespace ABAS.ABAS_Price_Calculus;

table 50104 "Price Calculus Setup Table"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = AsReadWrite;
        }

        field(10; "Rebate Base %"; Decimal)
        {
            AllowInCustomizations = AsReadWrite;
            Caption = 'Rebate Base %';
            DecimalPlaces = 0 : 2;
            MinValue = 0;
            MaxValue = 99;

            trigger OnValidate()
            begin
                if (Rec."Rebate Base %" < 0) or (Rec."Rebate Base %" > 99) then
                    Error(RebateErrorMsg);
            end;
        }

        field(11; "Production Markup %"; Decimal)
        {
            AllowInCustomizations = AsReadWrite;
            Caption = 'Production Markup %';
            DecimalPlaces = 0 : 2;
            MinValue = 0;

            trigger OnValidate()
            begin
                if (Rec."Production Markup %" < 0) then
                    FieldError("Production Markup %", MarkupErrorMsg);
            end;
        }

        field(12; "Purchase Markup %"; Decimal)
        {
            AllowInCustomizations = AsReadWrite;
            Caption = 'Purchase Markup %';
            DecimalPlaces = 0 : 2;
            MinValue = 0;

            trigger OnValidate()
            begin
                if (Rec."Purchase Markup %" < 0) then
                    FieldError("Purchase Markup %", MarkupErrorMsg);
            end;
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }

    var
        RebateErrorMsg: Label 'Rebate Base Percentage must be between 0 and 99.';
        MarkupErrorMsg: Label 'must be non-negative';
}
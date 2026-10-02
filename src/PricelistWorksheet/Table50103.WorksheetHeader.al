table 50103 "Worksheet Header"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Primary Key"; Code[20]) { }
        field(2; "Price List Code"; Code[20])
        {
            Caption = 'Price List Code';
            TableRelation = "Price List Header".Code where(
                "Price Type" = const(Sale),
                "Amount Type" = filter(<> Discount)
            );

            trigger OnValidate()
            var
                PriceListHeader: Record "Price List Header";
            begin
                if PriceListHeader.Get("Price List Code") then
                    "Price List Description" := PriceListHeader.Description
                else
                    "Price List Description" := '';
            end;
        }
        field(3; "Price List Description"; Text[100])
        {
            Caption = 'Price List Description';
            Editable = false;
        }
        field(4; "Comparison Baseline"; Option)
        {
            Caption = 'Mode';
            OptionMembers = "Sales Price","Net Price";
            OptionCaption = 'Sales Price (Calc.),Net Price (Calc.)';
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}
/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-06
    Description: Table data for setup page.
*/

table 50104 "Price Calculus Setup Table"
{
    DataClassification = CustomerContent;
    InherentPermissions = R;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = CustomerContent;
        }
        field(10; "Rebate Base %"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Rebate Base %';
            DecimalPlaces = 0 : 2;
            MinValue = 0;
            MaxValue = 100;
        }
        field(11; "Production Markup %"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Production Markup %';
            DecimalPlaces = 0 : 2;
            MinValue = 0;
        }
        field(12; "Purchase Markup %"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Purchase Markup %';
            DecimalPlaces = 0 : 2;
            MinValue = 0;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
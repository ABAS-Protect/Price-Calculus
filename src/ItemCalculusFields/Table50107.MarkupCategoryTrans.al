/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-19
    Description: Define Markup Category translation.
*/

table 50107 "COMP Markup Category Trans"
{
    DataClassification = CustomerContent;
    Caption = 'ABAS Markup Category Translation';
    InherentPermissions = R;

    fields
    {
        field(1; "Category Code"; Code[20])
        {
            Caption = 'Category Code';
            TableRelation = "COMP Markup Category";
        }
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(PK; "Category Code", "Language Code") { Clustered = true; }
    }
}
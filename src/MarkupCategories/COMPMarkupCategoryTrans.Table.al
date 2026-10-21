/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-19
    Description: Define Markup Category translation.
*/

namespace ABAS.ABAS_Price_Calculus;

table 50107 "COMP Markup Category Trans"
{
    DataClassification = CustomerContent;
    AllowInCustomizations = AsReadWrite;
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
            TableRelation = System.Globalization.Language;
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(PK; "Category Code", "Language Code") { Clustered = true; }
    }
}
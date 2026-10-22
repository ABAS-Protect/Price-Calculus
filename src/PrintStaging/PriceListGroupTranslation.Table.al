/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-22
    Description: Multilingual translation mappings for custom print groups.
*/

namespace ABAS.ABAS_Price_Calculus;

using System.Globalization;

table 50109 "Price List Group Translation"
{
    Caption = 'Price List Group Translation';
    DataClassification = CustomerContent;
    InherentPermissions = R;

    fields
    {
        field(1; "Group Code"; Code[20])
        {
            AllowInCustomizations = AsReadWrite;
            Caption = 'Group Code';
            TableRelation = "Price List Group".Code;
        }
        field(2; "Language Code"; Code[10])
        {
            AllowInCustomizations = AsReadWrite;
            Caption = 'Language Code';
            TableRelation = Language.Code;
        }
        field(3; "Description"; Text[50])
        {
            AllowInCustomizations = AsReadWrite;
            Caption = 'Translated Description';
        }
    }

    keys
    {
        key(PK; "Group Code", "Language Code") { Clustered = true; }
    }
}
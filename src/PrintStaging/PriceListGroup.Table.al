/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-22
    Description: Define print selection groups for PDF generation.
*/

namespace ABAS.ABAS_Price_Calculus;

table 50108 "Price List Group"
{
    Caption = 'Price List Group';
    DataClassification = CustomerContent;
    LookupPageId = "Price List Groups Lookup";
    InherentPermissions = R;

    fields
    {
        field(1; "Code"; Code[10])
        {
            AllowInCustomizations = AsReadWrite;
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Description"; Text[50])
        {
            AllowInCustomizations = AsReadWrite;
            Caption = 'Description';
        }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }

    trigger OnDelete()
    var
        GroupTranslation: Record "Price List Group Translation";
    begin
        GroupTranslation.SetRange("Group Code", Rec.Code);
        if not GroupTranslation.IsEmpty() then
            GroupTranslation.DeleteAll(true);
    end;

    procedure VerifyStandardGroupExists()
    var
        PriceListGroup: Record "Price List Group";
        StandardGroupLbl: Label 'Standard Catalog Group';
    begin
        if not PriceListGroup.Get('STANDARD') then begin
            PriceListGroup.Init();
            PriceListGroup.Code := 'STANDARD';
            PriceListGroup.Description := StandardGroupLbl;
            PriceListGroup.Insert(true);
        end;
    end;
}
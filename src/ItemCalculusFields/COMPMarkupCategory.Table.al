/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-19
    Description: Define Markup Category list in dropdown.
*/

namespace ABAS.ABAS_Price_Calculus;

using System.Globalization;

table 50106 "COMP Markup Category"
{
    DataClassification = CustomerContent;
    AllowInCustomizations = AsReadWrite;
    LookupPageId = "COMP Markup Categories";
    DrillDownPageId = "COMP Markup Categories";
    InherentPermissions = R;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(3; "Markup %"; Integer)
        {
            Caption = 'Markup %';
            MinValue = 0;
        }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
        key(SortByPercentage; "Markup %") { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, Description, "Markup %") { }
    }

    trigger OnModify()
    var
        Item: Record Microsoft.Inventory.Item.Item;
    begin
        Item.SetRange("COMP Markup Category", Rec.Code);
        if not Item.IsEmpty() then
            Item.ModifyAll("COMP Markup", Rec."Markup %", true);
    end;

    trigger OnDelete()
    var
        CannotDeleteStandardErr: Label 'The STANDARD markup category is a core system default and cannot be deleted.';
    begin
        if Rec.Code = 'STANDARD' then
            Error(CannotDeleteStandardErr);
    end;

    trigger OnRename()
    var
        CannotRenameStandardErr: Label 'The STANDARD markup category is a core system default and cannot be renamed.';
    begin
        if xRec.Code = 'STANDARD' then
            Error(CannotRenameStandardErr);
    end;

    procedure GetTranslatedDescription(): Text[250]
    var
        CategoryTranslation: Record "COMP Markup Category Trans";
        LanguageRecord: Record "Language";
        GlobalLanguageMgt: Codeunit "Language";
        TargetLanguageCode: Code[10];
    begin
        LanguageRecord.SetRange("Windows Language ID", GlobalLanguageMgt.GetLanguageIdOrDefault(GlobalLanguageMgt.GetUserLanguageCode()));
        if LanguageRecord.FindFirst() then
            TargetLanguageCode := LanguageRecord.Code
        else begin
            LanguageRecord.SetRange(Code, CopyStr(GlobalLanguageMgt.GetUserLanguageCode(), 1, MaxStrLen(LanguageRecord.Code)));
            if LanguageRecord.FindFirst() then
                TargetLanguageCode := LanguageRecord.Code;
        end;

        if (TargetLanguageCode <> '') and CategoryTranslation.Get(Rec.Code, TargetLanguageCode) then
            exit(CategoryTranslation.Description);

        exit(Rec.Description);
    end;
}
/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-22
    Description: Lookup list for print catalog groups.
*/

namespace ABAS.ABAS_Price_Calculus;

using System.Globalization;

page 50112 "Price List Groups Lookup"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Tasks;
    SourceTable = "Price List Group";
    Caption = 'Price List Groups';

    layout
    {
        area(Content)
        {
            repeater(GroupFields)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Unique catalog group code.';

                    trigger OnValidate()
                    begin
                        if (Rec.Code <> 'STANDARD') and (XRec.Code = 'STANDARD') then
                            Error('The mandatory STANDARD group cannot be renamed.');
                    end;
                }
                field("Description"; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Group description context.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Translations)
            {
                ApplicationArea = All;
                Caption = 'Translations';
                ToolTip = 'Define multi-language translations for the selected group description.';
                Image = Translations;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    GroupTranslation: Record "Price List Group Translation";
                begin
                    GroupTranslation.FilterGroup(2);
                    GroupTranslation.SetRange("Group Code", Rec.Code);
                    GroupTranslation.FilterGroup(0);

                    Page.RunModal(Page::"Price Group Translations", GroupTranslation);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        if Found then
            this.SwapWithTranslatedText();
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        ResultSteps: Integer;
    begin
        ResultSteps := Rec.Next(Steps);
        if ResultSteps <> 0 then
            this.SwapWithTranslatedText();
        exit(ResultSteps);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        if Rec.Code = 'STANDARD' then
            Error('The STANDARD pricing configuration group is mandatory and cannot be deleted.');
    end;

    local procedure SwapWithTranslatedText()
    var
        GroupTranslation: Record "Price List Group Translation";
        LanguageCodeunit: Codeunit Language;
        UserLanguageCode: Code[10];
    begin
        UserLanguageCode := LanguageCodeunit.GetLanguageCode(GlobalLanguage());
        if UserLanguageCode <> '' then
            if GroupTranslation.Get(Rec.Code, UserLanguageCode) then
                if GroupTranslation.Description <> '' then
                    Rec.Description := GroupTranslation.Description;
    end;
}
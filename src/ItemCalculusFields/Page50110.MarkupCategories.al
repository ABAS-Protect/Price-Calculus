/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-19
    Description: Define list with Markup Categories, with translation.
*/

page 50110 "COMP Markup Categories"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "COMP Markup Category";
    Caption = 'ABAS Markup Categories';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Markup %"; Rec."Markup %")
                {
                    ApplicationArea = All;
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
                Image = Translations;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Define descriptions in other languages.';

                trigger OnAction()
                var
                    CategoryTranslation: Record "COMP Markup Category Trans";
                begin
                    CategoryTranslation.SetRange("Category Code", Rec.Code);
                    Page.RunModal(Page::"COMP Markup Cat. Trans Sub", CategoryTranslation);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.Description := Rec.GetTranslatedDescription();
    end;
}
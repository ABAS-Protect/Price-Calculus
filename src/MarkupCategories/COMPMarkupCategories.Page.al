/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-19
    Description: Define list with Markup Categories, with translation.
*/

namespace ABAS.ABAS_Price_Calculus;

page 50110 "COMP Markup Categories"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "COMP Markup Category";
    Caption = 'ABAS Markup Categories';
    SourceTableView = sorting("Markup %") order(ascending);

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Price Calculus Group Code';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Price Calculus Group Description';
                }
                field("Markup %"; Rec."Markup %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Price Calculus Group Markup Percentage';
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
                PromotedOnly = true;
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
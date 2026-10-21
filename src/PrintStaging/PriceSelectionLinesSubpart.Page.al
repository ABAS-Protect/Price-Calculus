/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-12
    Description: Sorting price lists.
*/

namespace ABAS.ABAS_Price_Calculus;

page 50109 "Price Selection Lines Subpart"
{
    PageType = ListPart;
    SourceTable = "Price List Print Line";
    SourceTableView = sorting("Worksheet Code", "Sequence");
    Caption = ' Sorting';

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Sequence"; Rec."Sequence")
                {
                    ApplicationArea = All;
                    ToolTip = 'Price List Sequence';
                    StyleExpr = this.LineStyle;
                }
                field("Price List Code"; Rec."Price List Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Price List Code';
                    StyleExpr = this.LineStyle;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Price List Description';
                    StyleExpr = this.LineStyle;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Price List Status';
                    StyleExpr = this.LineStyle;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MoveUp)
            {
                Caption = 'Move Up';
                Image = MoveUp;
                ApplicationArea = All;
                ToolTip = 'Move price list item upwards.';
                Scope = Repeater;

                trigger OnAction()
                var
                    PreviousLine: Record "Price List Print Line";
                    CurrentSequence: Integer;
                begin
                    PreviousLine.SetRange("Worksheet Code", Rec."Worksheet Code");
                    PreviousLine.SetFilter("Sequence", '<%1', Rec."Sequence");
                    PreviousLine.SetCurrentKey("Worksheet Code", "Sequence");

                    if PreviousLine.FindLast() then begin
                        CurrentSequence := Rec."Sequence";
                        Rec."Sequence" := PreviousLine."Sequence";
                        Rec.Modify();

                        PreviousLine."Sequence" := CurrentSequence;
                        PreviousLine.Modify();

                        CurrPage.Update(false);
                    end;
                end;
            }

            action(MoveDown)
            {
                Caption = 'Move Down';
                Image = MoveDown;
                ApplicationArea = All;
                ToolTip = 'Move price list item downwards.';
                Scope = Repeater;

                trigger OnAction()
                var
                    NextLine: Record "Price List Print Line";
                    CurrentSequence: Integer;
                begin
                    NextLine.SetRange("Worksheet Code", Rec."Worksheet Code");
                    NextLine.SetFilter("Sequence", '>%1', Rec."Sequence");
                    NextLine.SetCurrentKey("Worksheet Code", "Sequence");

                    if NextLine.FindFirst() then begin
                        CurrentSequence := Rec."Sequence";
                        Rec."Sequence" := NextLine."Sequence";
                        Rec.Modify();

                        NextLine."Sequence" := CurrentSequence;
                        NextLine.Modify();

                        CurrPage.Update(false);
                    end;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields(Status);
        this.SetLineStyle();
    end;

    var
        LineStyle: Text;

    local procedure SetLineStyle()
    begin
        if Rec.Status = Rec.Status::Draft then
            this.LineStyle := 'Unfavorable'
        else
            this.LineStyle := 'None';
    end;
}
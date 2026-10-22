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

    InsertAllowed = false;
    DeleteAllowed = true;
    Editable = true;
    DelayedInsert = true;

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
                    CurrentLine: Record "Price List Print Line";
                    CurrentSequence: Integer;
                begin
                    PreviousLine.Reset();
                    PreviousLine.SetCurrentKey("Worksheet Code", "Sequence");
                    PreviousLine.SetRange("Worksheet Code", Rec."Worksheet Code");
                    PreviousLine.SetFilter("Sequence", '<%1', Rec."Sequence");

                    if PreviousLine.FindLast() then begin
                        CurrentSequence := Rec."Sequence";

                        if CurrentLine.Get(Rec."Worksheet Code", Rec."Line No.") then begin
                            CurrentLine."Sequence" := PreviousLine."Sequence";
                            CurrentLine.Modify();
                        end;

                        PreviousLine."Sequence" := CurrentSequence;
                        PreviousLine.Modify();

                        Rec.Get(Rec."Worksheet Code", Rec."Line No.");
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
                    CurrentLine: Record "Price List Print Line";
                    CurrentSequence: Integer;
                begin
                    NextLine.Reset();
                    NextLine.SetCurrentKey("Worksheet Code", "Sequence");
                    NextLine.SetRange("Worksheet Code", Rec."Worksheet Code");
                    NextLine.SetFilter("Sequence", '>%1', Rec."Sequence");

                    if NextLine.FindFirst() then begin
                        CurrentSequence := Rec."Sequence";

                        if CurrentLine.Get(Rec."Worksheet Code", Rec."Line No.") then begin
                            CurrentLine."Sequence" := NextLine."Sequence";
                            CurrentLine.Modify();
                        end;

                        NextLine."Sequence" := CurrentSequence;
                        NextLine.Modify();

                        Rec.Get(Rec."Worksheet Code", Rec."Line No.");
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

    procedure FilterSubpageLines(TargetGroupCode: Code[20])
    begin
        Rec.Reset();

        Rec.SetCurrentKey("Worksheet Code", "Sequence");

        Rec.FilterGroup(2);
        Rec.SetRange("Worksheet Code", TargetGroupCode);
        Rec.FilterGroup(0);

        CurrPage.Update(false);
    end;
}
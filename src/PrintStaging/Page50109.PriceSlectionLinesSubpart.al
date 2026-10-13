/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-12
    Description: Sorting price lists.
*/

page 50109 "Price Selection Lines Subpart"
{
    PageType = ListPart;
    SourceTable = "Price List Print Line";
    SourceTableView = sorting("User ID", "Sequence");
    Caption = ' ', Locked = true;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Sequence"; Rec."Sequence")
                {
                    ApplicationArea = All;
                }
                field("Price List Code"; Rec."Price List Code")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
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
            action(MoveUp)
            {
                Caption = 'Move Up';
                Image = MoveUp;
                ApplicationArea = All;
                Scope = Repeater;

                trigger OnAction()
                var
                    PreviousLine: Record "Price List Print Line";
                    CurrentSequence: Integer;
                begin
                    PreviousLine.SetRange("User ID", Rec."User ID");
                    PreviousLine.SetFilter("Sequence", '<%1', Rec."Sequence");
                    PreviousLine.SetCurrentKey("User ID", "Sequence");

                    if PreviousLine.FindLast() then begin
                        CurrentSequence := Rec."Sequence";
                        Rec."Sequence" := PreviousLine."Sequence";
                        Rec.Modify();

                        PreviousLine."Sequence" := CurrentSequence;
                        PreviousLine.Modify();
                    end;
                end;
            }

            action(MoveDown)
            {
                Caption = 'Move Down';
                Image = MoveDown;
                ApplicationArea = All;
                Scope = Repeater;

                trigger OnAction()
                var
                    NextLine: Record "Price List Print Line";
                    CurrentSequence: Integer;
                begin
                    NextLine.SetRange("User ID", Rec."User ID");
                    NextLine.SetFilter("Sequence", '>%1', Rec."Sequence");
                    NextLine.SetCurrentKey("User ID", "Sequence");

                    if NextLine.FindFirst() then begin
                        CurrentSequence := Rec."Sequence";
                        Rec."Sequence" := NextLine."Sequence";
                        Rec.Modify();

                        NextLine."Sequence" := CurrentSequence;
                        NextLine.Modify();
                    end;
                end;
            }
        }
    }

    procedure TriggerPopulate()
    begin
        Rec.PopulatePriceLists(UserId());
        CurrPage.Update(false);
    end;
}
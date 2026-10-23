/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-12
    Description: Worksheet to select pricelists for inclusion in PDF printout.
*/

namespace ABAS.ABAS_Price_Calculus;

using System.Globalization;

page 50108 "Price List Selection Worksheet"
{
    PageType = Worksheet;
    UsageCategory = Tasks;
    ApplicationArea = All;
    Caption = 'ABAS Print Price List Builder';

    layout
    {
        area(Content)
        {
            group(GroupSelectionPanel)
            {
                Caption = 'Group Filter Selection';

                field(SelectedGroupFilter; this.CurrentGroupCode)
                {
                    ApplicationArea = All;
                    Caption = 'Selected Catalog Group';
                    ToolTip = 'Choose which named layout group selection to manage or print.';
                    TableRelation = "Price List Group".Code;

                    trigger OnValidate()
                    begin
                        this.SyncSubpageData();
                    end;
                }
                field(ActiveGroupDescription; this.CurrentGroupDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Group Description';
                    ToolTip = 'Group description.';
                    Editable = false;
                }
            }

            part(CatalogLines; "Price Selection Lines Subpart")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PrintCatalog)
            {
                Caption = 'Generate PDF Catalog';
                ToolTip = 'Create a printable price list for the chosen group selection.';
                Image = PrintReport;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    PrintSelection: Record "Price List Print Line";
                begin
                    if this.CurrentGroupCode = '' then
                        exit;

                    PrintSelection.Reset();
                    PrintSelection.SetRange("Worksheet Code", this.CurrentGroupCode);

                    if not PrintSelection.IsEmpty() then
                        Report.Run(Report::"Combined Price List Report", true, false, PrintSelection)
                    else
                        Message('The chosen group worksheet is empty. Click "Reset Current Group Lines" to populate.');
                end;
            }
            action(ResetGroupLines)
            {
                Caption = 'Reset Current Group Lines';
                ToolTip = 'Clear out and fetch active sales price list matches cleanly for this group context.';
                Image = RefreshLines;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    PrintLineBuffer: Record "Price List Print Line";
                begin
                    if CurrentGroupCode = '' then
                        exit;

                    if Confirm('Completely rebuild entries for group alignment "%1"? This deletes custom sorting sequences.', false, this.CurrentGroupCode) then begin
                        PrintLineBuffer.PopulatePriceLists(this.CurrentGroupCode);
                        CurrPage.Update(false);
                    end;
                end;
            }
        }
    }

    var
        CurrentGroupCode: Code[20];
        CurrentGroupDescription: Text[100];

    trigger OnOpenPage()
    var
        GroupValidation: Record "Price List Group";
    begin
        GroupValidation.VerifyStandardGroupExists();

        CurrentGroupCode := 'STANDARD';
        this.SyncSubpageData();
    end;

    local procedure SyncSubpageData()
    var
        GroupRec: Record "Price List Group";
        SetupCheck: Record "Price List Print Line";
        GroupTranslation: Record "Price List Group Translation";
        LanguageCodeunit: Codeunit Language;
        UserLanguageCode: Code[10];
    begin
        if CurrentGroupCode <> '' then begin
            if GroupRec.Get(this.CurrentGroupCode) then begin
                UserLanguageCode := LanguageCodeunit.GetLanguageCode(GlobalLanguage());

                GroupTranslation.Reset();
                if GroupTranslation.Get(CurrentGroupCode, UserLanguageCode) then
                    this.CurrentGroupDescription := GroupTranslation.Description
                else
                    this.CurrentGroupDescription := GroupRec.Description;
            end else
                this.CurrentGroupDescription := '';

            SetupCheck.SetRange("Worksheet Code", this.CurrentGroupCode);
            if SetupCheck.IsEmpty() then
                SetupCheck.PopulatePriceLists(this.CurrentGroupCode);

            CurrPage.CatalogLines.PAGE.FilterSubpageLines(this.CurrentGroupCode);
        end else
            this.CurrentGroupDescription := '';

        CurrPage.Update(false);
    end;
}
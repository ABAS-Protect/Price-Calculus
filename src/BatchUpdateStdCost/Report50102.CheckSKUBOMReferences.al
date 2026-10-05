/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-05
    Description: Clean out ghost BOMs.
*/

report 50102 "Check SKU BOM References"
{
    UsageCategory = Tasks;
    ApplicationArea = All;
    ProcessingOnly = true;
    Caption = 'ABAS Check SKU BOM References';

    dataset
    { }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(DescriptionGroup)
                {
                    Caption = 'About This Utility';

                    field(ExplanationField; 'Automatically scan all Stockkeeping Unit (SKU) records to identify and remove invalid references to deleted or missing Production BOM Headers.')
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        MultiLine = true;
                        Editable = false;
                    }
                }
            }
        }
    }

    trigger OnPreReport()
    var
        SKU: Record "Stockkeeping Unit";
        ProdBOMHeader: Record "Production BOM Header";
        TotalSKUsChecked: Integer;
        FixedBOMsCount: Integer;
        ClearedKeysList: Text;
    begin
        SKU.SetFilter("Production BOM No.", '<>%1', '');

        if SKU.FindSet(true) then
            repeat
                TotalSKUsChecked += 1;

                if not ProdBOMHeader.Get(SKU."Production BOM No.") then begin
                    FixedBOMsCount += 1;

                    if StrLen(ClearedKeysList) < 150 then begin
                        if ClearedKeysList <> '' then
                            ClearedKeysList += ', ';
                        ClearedKeysList += SKU."Item No." + '(' + SKU."Location Code" + ')';
                    end;

                    SKU."Production BOM No." := '';
                    SKU.Modify();
                end;
            until SKU.Next() = 0;

        if FixedBOMsCount = 0 then
            Message('Cleanup Complete.\\Checked %1 SKUs.\\No ghost Production BOM references found to clear.', TotalSKUsChecked)
        else
            Message('Cleanup Complete.\\Checked %1 SKUs.\\Successfully erased %2 ghost references.\\Fixed SKU Keys: %3', TotalSKUsChecked, FixedBOMsCount, ClearedKeysList);
    end;
}

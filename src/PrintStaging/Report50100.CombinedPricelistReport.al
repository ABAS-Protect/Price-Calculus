/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-12
    Description: PDF printout RDLC data structure.
*/

report 50100 "Combined Price List Report"
{
    UsageCategory = None;
    DefaultLayout = RDLC;
    RDLCLayout = './Layouts/CombinedPriceList.rdl';
    Caption = 'Combined System Price Catalog';

    dataset
    {
        dataitem(SelectionLine; "Price List Print Line")
        {
            DataItemTableView = sorting("User ID", "Sequence");
            column(PriceListCode; "Price List Code") { }
            column(PriceListDescription; Description) { }
            column(SelectionLine_Sequence; "Sequence") { }

            dataitem(PriceLines; "Price List Line")
            {
                DataItemLink = "Price List Code" = field("Price List Code");
                DataItemTableView = sorting("Price List Code", "Asset No.");

                column(Item_No_; "Asset No.") { }
                column(Item_Description; ReportDescription) { }
                column(Unit_Price; "Unit Price") { }
                column(Variant_Code; "Variant Code") { }
                column(Unit_of_Measure_Code; "Unit of Measure Code") { }
                column(Description_2; ReportDescription2) { }

                trigger OnAfterGetRecord()
                var
                    Item: Record Item;
                    ItemTranslation: Record "Item Translation";
                    LanguageCodeunit: Codeunit Language;
                    UserLanguageCode: Code[10];
                begin
                    ReportDescription := PriceLines.Description;
                    ReportDescription2 := '';

                    if (PriceLines."Asset Type" = PriceLines."Asset Type"::Item) and (PriceLines."Asset No." <> '') then begin
                        if Item.Get(PriceLines."Asset No.") then begin
                            if ReportDescription = '' then
                                ReportDescription := Item.Description;
                            ReportDescription2 := Item."Description 2";

                            UserLanguageCode := LanguageCodeunit.GetLanguageCode(GlobalLanguage());

                            if UserLanguageCode <> '' then begin
                                ItemTranslation.SetRange("Item No.", Item."No.");
                                ItemTranslation.SetRange("Language Code", UserLanguageCode);
                                if ItemTranslation.FindFirst() then begin
                                    if ItemTranslation.Description <> '' then
                                        ReportDescription := ItemTranslation.Description;
                                    if ItemTranslation."Description 2" <> '' then
                                        ReportDescription2 := ItemTranslation."Description 2";
                                    if ItemTranslation."Variant Code" <> '' then
                                        ReportDescription2 := ItemTranslation."Variant Code";
                                end;
                            end;
                        end;
                    end;
                end;
            }
        }
    }

    labels
    {
        ReportTitleLbl = 'Combined Price Catalog';
        ItemNoLbl = 'Item No.';
        DescriptionLbl = 'Description';
        VariantLbl = 'Variant';
        PriceLbl = 'Unit Price';
    }

    var
        ReportDescription: Text;
        ReportDescription2: Text[100];
}
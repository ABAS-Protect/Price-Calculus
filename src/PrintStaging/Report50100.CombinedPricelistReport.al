/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-12
    Description: PDF printout RDLC data structure.
*/

report 50100 "Combined Price List Report"
{
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './Layouts/CombinedPriceList.rdl';
    EnableHyperlinks = true;
    Caption = 'Combined System Price Catalog';

    dataset
    {
        dataitem(SelectionLine; "Price List Print Line")
        {
            DataItemTableView = sorting("Worksheet Code", "Sequence");
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
                column(Unit_of_Measure_Code; ReportUOMText) { }
                column(Description_2; ReportDescription2) { }
                column(IsPriceAndDiscount; IsPriceAndDiscount) { }

                trigger OnAfterGetRecord()
                var
                    Item: Record Item;
                    ItemTranslation: Record "Item Translation";
                    UnitOfMeasure: Record "Unit of Measure";
                    UnitOfMeasureTranslation: Record "Unit of Measure Translation";
                    PriceListHeader: Record "Price List Header";
                    LanguageCodeunit: Codeunit Language;
                    UserLanguageCode: Code[10];
                begin
                    IsPriceAndDiscount := false;

                    ReportDescription := PriceLines.Description;
                    ReportDescription2 := '';
                    ReportUOMText := PriceLines."Unit of Measure Code";

                    if PriceListHeader.Get(PriceLines."Price List Code") then begin
                        if PriceListHeader."Amount Type" = "Price Amount Type"::Any then
                            IsPriceAndDiscount := true;
                    end;

                    if (PriceLines."Asset Type" = PriceLines."Asset Type"::Item) and (PriceLines."Asset No." <> '') then begin
                        if Item.Get(PriceLines."Asset No.") then begin
                            if ReportDescription = '' then
                                ReportDescription := Item.Description;
                            ReportDescription2 := Item."Description 2";

                            UserLanguageCode := LanguageCodeunit.GetLanguageCode(GlobalLanguage());

                            if UserLanguageCode <> '' then begin
                                ItemTranslation.SetRange("Item No.", Item."No.");
                                ItemTranslation.SetRange("Language Code", UserLanguageCode);
                                ItemTranslation.SetRange("Variant Code", PriceLines."Variant Code");
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

                    if PriceLines."Unit of Measure Code" <> '' then begin
                        if UnitOfMeasure.Get(PriceLines."Unit of Measure Code") then begin
                            if UnitOfMeasure.Description <> '' then
                                ReportUOMText := UnitOfMeasure.Description;
                        end;

                        if UserLanguageCode <> '' then begin
                            UnitOfMeasureTranslation.SetRange(Code, PriceLines."Unit of Measure Code");
                            UnitOfMeasureTranslation.SetRange("Language Code", UserLanguageCode);
                            if UnitOfMeasureTranslation.FindFirst() then begin
                                if UnitOfMeasureTranslation.Description <> '' then
                                    ReportUOMText := UnitOfMeasureTranslation.Description;
                            end;
                        end;
                    end;
                end;
            }
        }
    }

    labels
    {
        ReportTitleLbl = 'ABAS Price List';
        ItemNoLbl = 'Item No.';
        DescriptionLbl = 'Description';
        Description2Lbl = 'Description 2';
        VariantLbl = 'Code';
        UnitCode = 'Unit';
        PriceLbl = 'Price';
    }

    var
        ReportDescription: Text;
        ReportDescription2: Text[100];
        ReportUOMText: Text;
        IsPriceAndDiscount: Boolean;
}
/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-12
    Description: PDF printout RDLC data structure.
*/

namespace ABAS.ABAS_Price_Calculus;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.PriceList;
using System.Globalization;

report 50100 "Combined Price List Report"
{
    ApplicationArea = All;
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
                column(Item_Description; this.ReportDescription) { }
                column(Unit_Price; "Unit Price") { }
                column(Variant_Code; "Variant Code") { }
                column(Unit_of_Measure_Code; this.ReportUOMText) { }
                column(Description_2; this.ReportDescription2) { }
                column(IsPriceAndDiscount; this.IsPriceAndDiscount) { }

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
                    this.IsPriceAndDiscount := false;

                    this.ReportDescription := PriceLines.Description;
                    this.ReportDescription2 := '';
                    this.ReportUOMText := PriceLines."Unit of Measure Code";

                    if PriceListHeader.Get(PriceLines."Price List Code") then
                        if PriceListHeader."Amount Type" = "Price Amount Type"::Any then
                            this.IsPriceAndDiscount := true;

                    if (PriceLines."Asset Type" = PriceLines."Asset Type"::Item) and (PriceLines."Asset No." <> '') then
                        if Item.Get(PriceLines."Asset No.") then begin
                            if this.ReportDescription = '' then
                                this.ReportDescription := Item.Description;
                            this.ReportDescription2 := Item."Description 2";

                            UserLanguageCode := LanguageCodeunit.GetLanguageCode(GlobalLanguage());

                            if UserLanguageCode <> '' then begin
                                ItemTranslation.SetRange("Item No.", Item."No.");
                                ItemTranslation.SetRange("Language Code", UserLanguageCode);
                                ItemTranslation.SetRange("Variant Code", PriceLines."Variant Code");
                                if ItemTranslation.FindFirst() then begin
                                    if ItemTranslation.Description <> '' then
                                        this.ReportDescription := ItemTranslation.Description;
                                    if ItemTranslation."Description 2" <> '' then
                                        this.ReportDescription2 := ItemTranslation."Description 2";
                                    if ItemTranslation."Variant Code" <> '' then
                                        this.ReportDescription2 := ItemTranslation."Variant Code";
                                end;
                            end;
                        end;

                    if PriceLines."Unit of Measure Code" <> '' then begin
                        if UnitOfMeasure.Get(PriceLines."Unit of Measure Code") then
                            if UnitOfMeasure.Description <> '' then
                                this.ReportUOMText := UnitOfMeasure.Description;

                        if UserLanguageCode <> '' then begin
                            UnitOfMeasureTranslation.SetRange(Code, PriceLines."Unit of Measure Code");
                            UnitOfMeasureTranslation.SetRange("Language Code", UserLanguageCode);
                            if UnitOfMeasureTranslation.FindFirst() then
                                if UnitOfMeasureTranslation.Description <> '' then
                                    this.ReportUOMText := UnitOfMeasureTranslation.Description;
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
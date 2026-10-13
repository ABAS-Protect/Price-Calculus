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
                column(Item_Description; Description) { }
                column(Unit_Price; "Unit Price") { }
            }
        }
    }
}
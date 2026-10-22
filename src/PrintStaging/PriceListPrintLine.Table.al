/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-12
    Description: Table definitions for price list worksheet.
*/

namespace ABAS.ABAS_Price_Calculus;

using Microsoft.Pricing.PriceList;
using Microsoft.Sales.Setup;

table 50105 "Price List Print Line"
{
    Caption = 'ABAS Print Price List';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Worksheet Code"; Code[20])
        {
            AllowInCustomizations = AsReadWrite;
            Caption = 'Worksheet Code';
            TableRelation = "Price List Group".Code;
        }
        field(2; "Line No."; Integer)
        {
            AllowInCustomizations = AsReadWrite;
            Caption = 'Line No.';
        }

        field(3; "Price List Code"; Code[20])
        {
            AllowInCustomizations = AsReadWrite;
            Caption = 'Price List Code';
            TableRelation = "Price List Header".Code;

            trigger OnValidate()
            var
                PriceListHeader: Record "Price List Header";
            begin
                if PriceListHeader.Get("Price List Code") then
                    "Description" := PriceListHeader.Description;
            end;
        }

        field(4; "Description"; Text[250])
        {
            Caption = 'Description';
            Editable = false;
        }
        field(5; "Sequence"; Integer)
        {
            AllowInCustomizations = AsReadWrite;
            Caption = 'Sequence Order';
        }
        field(6; "Status"; Enum "Price Status")
        {
            Caption = 'Status';
            FieldClass = FlowField;
            CalcFormula = lookup("Price List Header".Status where(Code = field("Price List Code")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Worksheet Code", "Line No.") { Clustered = true; }
        key(SortKey; "Worksheet Code", "Sequence") { }
    }

    procedure PopulatePriceLists(TargetGroupCode: Code[20])
    var
        PriceListHeader: Record "Price List Header";
        PrintLine: Record "Price List Print Line";
        GlobalLineCounter: Record "Price List Print Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NextLineNo: Integer;
        NextSequence: Integer;
    begin
        if TargetGroupCode = '' then
            exit;

        PrintLine.SetRange("Worksheet Code", TargetGroupCode);
        if not PrintLine.IsEmpty() then
            PrintLine.DeleteAll(false);

        PriceListHeader.SetRange("Price Type", PriceListHeader."Price Type"::Sale);
        PriceListHeader.SetFilter(Status, '%1|%2', PriceListHeader.Status::Active, PriceListHeader.Status::Draft);
        PriceListHeader.SetFilter("Amount Type", '<>%1', PriceListHeader."Amount Type"::Discount);

        if SalesReceivablesSetup.Get() then
            if SalesReceivablesSetup."Default Price List Code" <> '' then
                PriceListHeader.SetFilter(Code, '<>%1', SalesReceivablesSetup."Default Price List Code");

        if PriceListHeader.FindSet() then begin
            GlobalLineCounter.Reset();
            if GlobalLineCounter.FindLast() then
                NextLineNo := GlobalLineCounter."Line No." + 10000
            else
                NextLineNo := 10000;

            NextSequence := 10;

            repeat
                PrintLine.Init();
                PrintLine."Worksheet Code" := TargetGroupCode;
                PrintLine."Line No." := NextLineNo;
                PrintLine."Price List Code" := PriceListHeader.Code;
                PrintLine.Description := PriceListHeader.Description;
                PrintLine."Sequence" := NextSequence;
                PrintLine.Insert();

                NextLineNo += 10000;
                NextSequence += 10;
            until PriceListHeader.Next() = 0;
        end;
    end;
}

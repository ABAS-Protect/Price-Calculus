table 50120 "Price List Print Line"
{
    Caption = 'ABAS Print Price List';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "User ID"; Code[50]) { Caption = 'User ID'; DataClassification = SystemMetadata; }
        field(2; "Line No."; Integer) { Caption = 'Line No.'; }
        field(3; "Price List Code"; Code[20])
        {
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
        field(4; "Description"; Text[100]) { Caption = 'Description'; Editable = false; }
        field(5; "Sequence"; Integer) { Caption = 'Sequence Order'; }
    }

    keys
    {
        key(PK; "User ID", "Line No.") { Clustered = true; }
        key(SortKey; "User ID", "Sequence") { }
    }

    procedure PopulatePriceLists(CurrentUserId: Code[20])
    var
        PriceListHeader: Record "Price List Header";
        PrintLine: Record "Price List Print Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NextLineNo: Integer;
        NextSequence: Integer;
    begin
        PrintLine.SetRange("User ID", CurrentUserId);
        if not PrintLine.IsEmpty() then
            PrintLine.DeleteAll(false);

        PriceListHeader.SetRange("Price Type", PriceListHeader."Price Type"::Sale);
        PriceListHeader.SetFilter(Status, '%1|%2', PriceListHeader.Status::Active, PriceListHeader.Status::Draft);
        PriceListHeader.SetFilter("Amount Type", '<>%1', PriceListHeader."Amount Type"::Discount);

        if SalesReceivablesSetup.Get() then begin
            if SalesReceivablesSetup."Default Price List Code" <> '' then
                PriceListHeader.SetFilter(Code, '<>%1', SalesReceivablesSetup."Default Price List Code");
        end;

        if PriceListHeader.FindSet() then begin
            NextLineNo := 10000;
            NextSequence := 10;

            repeat
                PrintLine.Init();
                PrintLine."User ID" := CurrentUserId;
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

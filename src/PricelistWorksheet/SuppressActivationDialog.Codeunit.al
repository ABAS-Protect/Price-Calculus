/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-23
    Description: Ignore dialog when reactivating active price lists.
*/

namespace ABAS.ABAS_Price_Calculus;

using Microsoft.Pricing.PriceList;

codeunit 50111 "Suppress Activation Dialog"
{
    [EventSubscriber(ObjectType::Table, Database::"Price List Header", 'OnUpdateStatusOnBeforeConfirmStatus', '', false, false)]
    local procedure SuppressActivationDialog(PriceListHeader: Record "Price List Header"; Updated: Boolean; var Confirmed: Boolean; var IsHandled: Boolean)
    begin
        if PriceListHeader.Status = PriceListHeader.Status::Active then begin
            Confirmed := true;
            IsHandled := true;
        end;
    end;
}

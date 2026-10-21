/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-06
    Description: Prevent modification of Item Card fields for unauthorized users.
*/

namespace ABAS.ABAS_Price_Calculus;

using Microsoft.Inventory.Item;
using System.Security.User;

pageextension 50111 "Item Card Permission Lock" extends "Item Card"
{
    layout
    {
        modify("COMP Markup")
        {
            Editable = IsCalculationAdmin;
        }

        modify("COMP Comment")
        {
            Visible = IsCalculationAdmin;
            Editable = IsCalculationAdmin;
        }

        modify("COMP Markup Category")
        {
            Editable = IsCalculationAdmin;
        }
    }

    var
        IsCalculationAdmin: Boolean;

    trigger OnOpenPage()
    var
        UserPermissions: Codeunit "User Permissions";
    begin
        if UserPermissions.IsSuper(UserSecurityId()) then
            IsCalculationAdmin := true
        else
            IsCalculationAdmin := CheckUserHasRole('D365 BUS PREMIUM');
    end;

    local procedure CheckUserHasRole(PermissionSetID: Code[20]): Boolean
    var
        AccessControl: Record 2000000053; // System.Security.AccessControl."Access Control"
    begin
        AccessControl.SetRange("User Security ID", UserSecurityId());
        AccessControl.SetRange("Role ID", PermissionSetID);
        AccessControl.SetFilter("Company Name", '%1|%2', '', CompanyName());
        exit(not AccessControl.IsEmpty());
    end;
}
/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-06
    Description: Prevent modification of Item Card fields for unauthorized users.
*/

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
            IsCalculationAdmin := CheckUserHasRole('ABAS Price Calculus');
    end;

    local procedure CheckUserHasRole(PermissionSetID: Code[20]): Boolean
    var
        AccessControl: Record 2000000053;
    begin
        AccessControl.SetRange("User Security ID", UserSecurityId());
        AccessControl.SetRange("Role ID", PermissionSetID);
        AccessControl.SetFilter("Company Name", '%1|%2', '', CompanyName());
        exit(not AccessControl.IsEmpty());
    end;
}
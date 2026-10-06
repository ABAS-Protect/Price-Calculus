/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-10-06
    Description: Required permission extension for admin functions.
*/

permissionsetextension 50101 "Extend D365 Bus Premium" extends "D365 BUS PREMIUM"
{
    IncludedPermissionSets = "ABAS Calculus Admin";
}

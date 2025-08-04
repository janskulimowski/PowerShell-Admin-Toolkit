<#
.SYNOPSIS
Quickly retrieves detailed information about Active Directory user accounts.

.DESCRIPTION
This script allows IT administrators to retrieve and display key information about one or more Active Directory users, 
without manually browsing through tools like Active Directory Users and Computers (ADUC).

It returns attributes such as:
- Display name
- Department / OU
- Account status (enabled/locked)
- Last logon date
- Password expiry
- Group membership
- and more...

Useful for audits, troubleshooting, onboarding/offboarding, and helpdesk support.

.PARAMETER Path
Optional. Path to a CSV file containing one or more user logins (sAMAccountName) under the header "Username".

.EXAMPLE
.\Get-ADUserInfo.ps1 -Path .\users.csv

.EXAMPLE
.\Get-ADUserInfo.ps1
# The script will prompt you to enter a single username manually.

.REQUIREMENTS
- PowerShell 7.0+
- ActiveDirectory Module for Windows PowerShell
- Domain-joined machine with AD access

.NOTES
Author: janskulimowski 
Created: 2025-08-05  
Version: 1.0  
Run as: Administrator (elevated privileges)
#>


param ([string]$Path)
Import-Module ActiveDirectory

function ReportUser {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Username
	)
    try {
        $user = Get-ADUser -Identity $Username -Properties `
            DisplayName, GivenName, Surname, UserPrincipalName, `
            EmailAddress, Title, Department, Office, Enabled, `
            LastLogonDate, PasswordLastSet, Manager, MemberOf, `
            WhenCreated, AccountExpirationDate, PasswordNeverExpires, LockedOut

        if (-not $user) {
            Write-Warning "User '$username' not found in Active Directory."
            return
        }
		Write-Host ""
		Write-Host "=========================================================" -ForegroundColor Blue
        Write-Host "=== Active Directory User - $($user.DisplayName) - Report ===" -ForegroundColor Cyan
        Write-Host "Name:                $($user.DisplayName ?? 'NOT SET')"
        Write-Host "Username (sAM):      $($user.SamAccountName ?? 'NOT SET')"
        Write-Host "First Name:          $($user.GivenName ?? 'NOT SET')"
        Write-Host "Last Name:           $($user.Surname ?? 'NOT SET')"
        Write-Host "UPN:                 $($user.UserPrincipalName ?? 'NOT SET')"
        Write-Host "Email:               $($user.EmailAddress ?? 'NOT SET')"
        Write-Host "Title:               $($user.Title ?? 'NOT SET')"
        Write-Host "Department:          $($user.Department ?? 'NOT SET')"
		Write-Host "Manager:             $($user.Manager ?? 'NOT SET')"
        Write-Host "Office:              $($user.Office ?? 'NOT SET')"
        Write-Host "Account Enabled:     $($user.Enabled)"
		Write-Host "Account Locked:		 $($user.LockedOut ?? 'No')"
		Write-Host "Password Never Expires:    $($user.PasswordNeverExpires)"
		Write-Host ""
		Write-Host "========= Date format =========" -ForegroundColor Cyan
		Write-Host "          (MM-DD-YY)          " -ForegroundColor Cyan
        Write-Host "Last Logon:          $($user.LastLogonDate ?? 'no data')"
        Write-Host "Password Last Set:   $($user.PasswordLastSet ?? 'no data')"
        Write-Host "Account Created:     $($user.WhenCreated ?? 'no data')"
        Write-Host "Account Expires:     $($user.AccountExpirationDate ?? 'no data')"
        Write-Host ""
		Write-Host "========= Groups =========" -ForegroundColor Cyan
        Write-Host "Member Of:"
        $groups = $user.MemberOf | ForEach-Object {
            ($_ -split ',')[0] -replace '^CN='
        }
        foreach ($g in $groups) {
            Write-Host "  - $g"
        }

        Write-Host "===================================" -ForegroundColor Cyan
		Write-Host "=========================================================" -ForegroundColor Blue
		Write-Host ""
    } catch {
        Write-Error "Error: $_"
    }
}


if ($Path) {
   Write-Host "Loading data from file: $Path"
   $users = Import-Csv -Path $Path
   if (-not $users[0].PSObject.Properties.Name -contains 'Username') {
    Write-Error "CSV is missing required 'Username' column."
    return
}
   foreach ($u in $users) {
			$username = $u.Username
			ReportUser $username
        }
}else {
    $username = Read-Host "Enter the domain username:"
    Write-Host "Entered user: $username"
	ReportUser $username
    
}










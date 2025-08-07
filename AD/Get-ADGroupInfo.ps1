<#
.SYNOPSIS
Quickly retrieves information about Active Directory groups (and members).

.DESCRIPTION
This script allows IT administrators to retrieve, display information about all Active Directory groups and their members, 
without manually browsing through tools like Active Directory Users and Computers (ADUC).

It returns attributes such as:
- Group name
- Description
- Group category (Security/Distribution)
- Group scope (Global/Universal/Domain Local)
- Managed by (if set)
- Members (list of group members)

Useful for audits, troubleshooting, onboarding/offboarding, and helpdesk support.

.EXAMPLE
.\Get-ADGroupInfo.ps1
# The script will generate a report about all Active Directory groups in the domain.

.REQUIREMENTS
- PowerShell 7.0+
- ActiveDirectory Module for Windows PowerShell
- Domain-joined machine with AD access and privilages

.NOTES
Author: janskulimowski 
Created: 2025-08-07  
Version: 1.0  
Run as: Administrator (elevated privileges)
#>

$style = @"
<style>
    body {
        font-family: Arial, sans-serif;
        font-size: 13px;
        background-color: #f9f9f9;
    }

    table {
        border-collapse: collapse;
        width: 100%;
        table-layout: fixed;
    }

    th, td {
        border: 1px solid #ccc;
        padding: 6px;
        text-align: left;
        vertical-align: top;
        word-wrap: break-word;
        white-space: pre-wrap;
    }

    th {
        background-color: #e0e0e0;
    }

    td:last-child {
        max-height: 200px; /* wysokość do której się rozwija */
        overflow-y: auto;  /* pojawia się pasek przewijania przy wielu danych */
        display: block;    /* potrzebne by overflow-y działało */
    }

    tr:nth-child(even) {
        background-color: #f2f2f2;
    }
</style>
"@
# Function to retrieve and display information about all AD groups
function Get-ADGroupInfo {
    $groups = Get-ADGroup -Filter * -Properties Name, Description, GroupCategory, GroupScope, ManagedBy

        
    $report = foreach ($group in $groups) {
        $manager = if ($group.ManagedBy) { (Get-ADUser -Identity $group.ManagedBy -Properties DisplayName).DisplayName } else { "NOT SET" }
        $members = try { (Get-ADGroupMember -Identity $group.SamAccountName | Select-Object -ExpandProperty SamAccountName) -join ", " } catch { $members = "ERROR: $_" }
        # Create a custom object for each group
        [PSCustomObject]@{
            DisplayName = $group.Name
            Description = $group.Description
            Category    = $group.GroupCategory
            Scope       = $group.GroupScope
            Manager     = $manager
            Members     = $members
        
        }
        
    }
    return $report
}
# Import the Active Directory module
Import-Module ActiveDirectory
$date = Get-Date -Format "ddMMyy-HHmm"
# Check if the Active Directory module is available
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Error "Active Directory module is not available. Install RSAT tools or run on domain controller."
    exit
}
else {
    $report = Get-ADGroupInfo
    $reportpath = "$env:USERPROFILE\Desktop\report_ad_groups_$date.html"
    # Export the report to HTML
    $report | ConvertTo-Html -Head $style -PreContent "<h2>Raport grup AD</h2>" -Title "Report ADGroup Info" | Out-File $reportpath -Encoding UTF8
    Invoke-Item $reportpath
    Write-Host "Report generated successfully: $reportpath"
}


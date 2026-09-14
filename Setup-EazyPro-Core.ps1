<#
.SYNOPSIS
    Automated Infrastructure Setup for EazyPro Technologies AB.

.DESCRIPTION
    This script creates Organizational Units (OUs) and Security Groups 
    following the IGDLA model for the eazypro.local domain.
    Includes:
        - Parameterization
        - Logging
        - Error handling
        - Modular functions
        - Transcript output

.PARAMETER DomainPath
    Distinguished Name (DN) of the target domain.

.PARAMETER LogPath
    File path for the transcript log.

.EXAMPLE
    .\Setup-EazyPro-Core.ps1 -DomainPath "DC=eazypro,DC=local" -LogPath "C:\Logs\EazyPro.log"

.NOTES
    Author: Amrita Singh
    Role: Cloud & ICT Engineer
    Version: 2.0 (Enterprise-Grade)
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$DomainPath,

    [Parameter(Mandatory = $false)]
    [string]$LogPath = "C:\Logs\EazyPro-Automation.log"
)

# ------------------------------
# 0. Start Transcript Logging
# ------------------------------
if (!(Test-Path (Split-Path $LogPath))) {
    New-Item -ItemType Directory -Path (Split-Path $LogPath) -Force | Out-Null
}

Start-Transcript -Path $LogPath -Append

Write-Host "`n=== Starting EazyPro Infrastructure Automation ===" -ForegroundColor Cyan

# ------------------------------
# 1. Validate AD Module
# ------------------------------
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "ERROR: ActiveDirectory module not found. Install RSAT tools." -ForegroundColor Red
    Stop-Transcript
    exit
}

Import-Module ActiveDirectory

# ------------------------------
# 2. Functions
# ------------------------------

function New-EazyProOU {
    param([string]$OUName)

    try {
        if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$OUName'" -ErrorAction SilentlyContinue)) {
            New-ADOrganizationalUnit -Name $OUName -Path $DomainPath -ErrorAction Stop
            Write-Host "✓ Created OU: $OUName" -ForegroundColor Green
        }
        else {
            Write-Host "OU already exists: $OUName" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "✗ ERROR creating OU $OUName : $($_.Exception.Message)" -ForegroundColor Red
    }
}

function New-EazyProGroup {
    param(
        [string]$GroupName,
        [string]$GroupPath
    )

    try {
        if (-not (Get-ADGroup -Filter "Name -eq '$GroupName'" -ErrorAction SilentlyContinue)) {
            New-ADGroup -Name $GroupName -GroupScope Global -Path $GroupPath -ErrorAction Stop
            Write-Host "✓ Created Group: $GroupName" -ForegroundColor Green
        }
        else {
            Write-Host "Group already exists: $GroupName" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "✗ ERROR creating Group $GroupName : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ------------------------------
# 3. Create OUs
# ------------------------------

$OUs = @(
    "Management_VLAN80",
    "Users_VLAN70",
    "IoT_VLAN30",
    "Guests_VLAN60"
)

Write-Host "`n--- Creating Organizational Units ---" -ForegroundColor Cyan

foreach ($OU in $OUs) {
    New-EazyProOU -OUName $OU
}

# ------------------------------
# 4. Create Security Groups (IGDLA)
# ------------------------------

Write-Host "`n--- Creating Security Groups (IGDLA Model) ---" -ForegroundColor Cyan

# Sample groups — extend this array for full org structure
$SecurityGroups = @(
    @{ Name = "GG_EazyPro_Finance_Read"; Path = "OU=Users_VLAN70,$DomainPath" },
    @{ Name = "GG_EazyPro_IT_Admin";     Path = "OU=Management_VLAN80,$DomainPath" },
    @{ Name = "GG_EazyPro_Economy";      Path = "OU=Users_VLAN70,$DomainPath" },
    @{ Name = "GG_EazyPro_Board";        Path = "OU=Management_VLAN80,$DomainPath" }
)

foreach ($Group in $SecurityGroups) {
    New-EazyProGroup -GroupName $Group.Name -GroupPath $Group.Path
}

# ------------------------------
# 5. Completion
# ------------------------------

Write-Host "`n=== EazyPro Infrastructure Setup Complete ===" -ForegroundColor Cyan

Stop-Transcript

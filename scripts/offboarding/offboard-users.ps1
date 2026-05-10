# =========================================
# M365 Identity Automation Toolkit
# Offboarding Automation Script
# =========================================

Write-Host "=== OFFBOARDING SCRIPT STARTED ===" -ForegroundColor Yellow

# =========================================
# LOAD AUTH
# =========================================

. "$PSScriptRoot\..\config\auth.ps1"

Write-Host "Auth loaded" -ForegroundColor Green

# =========================================
# CONNECT TO MICROSOFT GRAPH
# =========================================

Connect-MgGraph `
    -TenantId $TenantId `
    -ClientSecretCredential $Credential `
    -NoWelcome

Write-Host "Connected to Microsoft Graph" -ForegroundColor Green

# =========================================
# CSV PATH
# =========================================

$csvPath = "$PSScriptRoot\..\input\offboard-users.csv"

Write-Host "Reading CSV: $csvPath" -ForegroundColor Cyan

# =========================================
# IMPORT USERS
# =========================================

$users = Import-Csv $csvPath

Write-Host "Users found: $($users.Count)" -ForegroundColor Yellow

# =========================================
# OFFBOARDING LOG FILE
# =========================================

$logPath = "$PSScriptRoot\..\..\logs\offboarding-log.csv"

if (-not (Test-Path $logPath)) {
    "Timestamp,Action,User,Status,Details" | Out-File $logPath
}

# =========================================
# PROCESS USERS
# =========================================

foreach ($user in $users) {

    Write-Host ""
    Write-Host "=========================================" -ForegroundColor DarkGray
    Write-Host "Processing offboarding: $($user.Email)" -ForegroundColor Cyan

    try {

        # =========================================
        # GET USER
        # =========================================

        $existingUser = Get-MgUser -Filter "userPrincipalName eq '$($user.Email)'"

        if (-not $existingUser) {

            Write-Host "SKIPPED: User not found -> $($user.Email)" -ForegroundColor Yellow
            continue
        }

        Write-Host "User found -> $($user.Email)" -ForegroundColor Green

        # =========================================
        # DISABLE ACCOUNT
        # =========================================

        Update-MgUser `
            -UserId $existingUser.Id `
            -AccountEnabled:$false

        Write-Host "SUCCESS: Account disabled" -ForegroundColor Green

        $logEntry = "$(Get-Date),Offboarding,$($user.Email),Success,Account disabled"
        Add-Content -Path $logPath -Value $logEntry

        # =========================================
        # REVOKE USER SESSIONS
        # =========================================

        Revoke-MgUserSignInSession `
            -UserId $existingUser.Id

        Write-Host "SUCCESS: User sessions revoked" -ForegroundColor Green

        $logEntry = "$(Get-Date),Offboarding,$($user.Email),Success,Sessions revoked"
        Add-Content -Path $logPath -Value $logEntry

        # =========================================
        # REMOVE USER FROM ALL GROUPS
        # =========================================

        $memberOf = Get-MgUserMemberOf -UserId $existingUser.Id

        foreach ($group in $memberOf) {

            try {

                Remove-MgGroupMemberByRef `
                    -GroupId $group.Id `
                    -DirectoryObjectId $existingUser.Id

                Write-Host "SUCCESS: Removed from group -> $($group.Id)" -ForegroundColor Green

                $logEntry = "$(Get-Date),Offboarding,$($user.Email),Success,Removed from group $($group.Id)"
                Add-Content -Path $logPath -Value $logEntry
            }
            catch {

                Write-Host "WARNING: Failed removing from group -> $($group.Id)" -ForegroundColor Yellow
            }
        }

        # =========================================
        # REMOVE LICENSES
        # =========================================

        $licenses = Get-MgUserLicenseDetail -UserId $existingUser.Id

        if ($licenses) {

            $removeLicenses = @()

            foreach ($license in $licenses) {

                $removeLicenses += $license.SkuId
            }

            Set-MgUserLicense `
                -UserId $existingUser.Id `
                -AddLicenses @() `
                -RemoveLicenses $removeLicenses

            Write-Host "SUCCESS: Licenses removed" -ForegroundColor Green

            $logEntry = "$(Get-Date),Offboarding,$($user.Email),Success,Licenses removed"
            Add-Content -Path $logPath -Value $logEntry
        }
        else {

            Write-Host "INFO: No licenses assigned" -ForegroundColor Cyan
        }

        # =========================================
        # OPTIONAL: DELETE USER
        # =========================================
        # Uncomment if you want permanent deletion
        #
        # Remove-MgUser -UserId $existingUser.Id
        # Write-Host \"SUCCESS: User deleted\" -ForegroundColor Red

        Write-Host "OFFBOARDING COMPLETE -> $($user.Email)" -ForegroundColor Green
    }
    catch {

        Write-Host "FAILED: $($user.Email)" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red

        $logEntry = "$(Get-Date),Offboarding,$($user.Email),Failed,$($_.Exception.Message)"
        Add-Content -Path $logPath -Value $logEntry
    }
}

Write-Host ""
Write-Host "=== OFFBOARDING SCRIPT COMPLETE ===" -ForegroundColor Yellow
# =========================================
# M365 Identity Automation Toolkit
# Onboarding Automation Script
# =========================================

Write-Host "=== SCRIPT STARTED ===" -ForegroundColor Yellow

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

$csvPath = "$PSScriptRoot\..\input\users.csv"

Write-Host "Reading CSV: $csvPath" -ForegroundColor Cyan

# =========================================
# IMPORT USERS
# =========================================

$users = Import-Csv $csvPath

Write-Host "Users found: $($users.Count)" -ForegroundColor Yellow

# =========================================
# LOG FILE
# =========================================

$logPath = "$PSScriptRoot\..\..\logs\onboarding-log.csv"

if (-not (Test-Path $logPath)) {

    "Timestamp,Action,User,Status,Details" | Out-File $logPath
}

# =========================================
# GROUP MAPPINGS
# =========================================

$departmentGroups = @{
    "IT"      = "IT-Department"
    "HR"      = "HR-Department"
    "Finance" = "Finance-Department"
}

# =========================================
# LICENSE GROUP
# =========================================

$licenseGroupName = "M365-License-Users"

# =========================================
# PROCESS USERS
# =========================================

foreach ($user in $users) {

    Write-Host ""
    Write-Host "=========================================" -ForegroundColor DarkGray
    Write-Host "Processing: $($user.FirstName) $($user.LastName)" -ForegroundColor Cyan

    $displayName = "$($user.FirstName) $($user.LastName)"
    $upn = $user.Email
    $mailNickname = $user.FirstName.ToLower()

    # =========================================
    # CHECK IF USER EXISTS
    # =========================================

    $existingUser = Get-MgUser -Filter "userPrincipalName eq '$upn'"

    if ($existingUser) {

        Write-Host "SKIPPED: User already exists -> $upn" -ForegroundColor Yellow

        $logEntry = "$(Get-Date),Onboarding,$upn,Skipped,User already exists"

        Add-Content -Path $logPath -Value $logEntry

        continue
    }

    try {

        # =========================================
        # CREATE USER
        # =========================================

        $createdUser = New-MgUser `
            -AccountEnabled:$true `
            -DisplayName $displayName `
            -MailNickname $mailNickname `
            -UserPrincipalName $upn `
            -Department $user.Department `
            -JobTitle $user.JobTitle `
            -PasswordProfile @{
                Password = "TempPassword123!"
                ForceChangePasswordNextSignIn = $true
            }

        if ($createdUser) {

            Write-Host "SUCCESS: User created -> $upn" -ForegroundColor Green

            $logEntry = "$(Get-Date),Onboarding,$upn,Success,User created successfully"

            Add-Content -Path $logPath -Value $logEntry
        }
        else {

            Write-Host "FAILED: User creation returned no object" -ForegroundColor Red
            continue
        }

        # =========================================
        # ADD TO DEPARTMENT GROUP
        # =========================================

        if ($departmentGroups.ContainsKey($user.Department)) {

            $groupName = $departmentGroups[$user.Department]

            $group = Get-MgGroup -Filter "displayName eq '$groupName'"

            if ($group) {

                New-MgGroupMember `
                    -GroupId $group.Id `
                    -DirectoryObjectId $createdUser.Id

                Write-Host "SUCCESS: Added to department group -> $groupName" -ForegroundColor Green
            }
            else {

                Write-Host "WARNING: Department group not found -> $groupName" -ForegroundColor Yellow
            }
        }
        else {

            Write-Host "WARNING: No group mapping for department -> $($user.Department)" -ForegroundColor Yellow
        }

        # =========================================
        # ADD TO LICENSE GROUP
        # =========================================

        $licenseGroup = Get-MgGroup -Filter "displayName eq '$licenseGroupName'"

        if ($licenseGroup) {

            New-MgGroupMember `
                -GroupId $licenseGroup.Id `
                -DirectoryObjectId $createdUser.Id

            Write-Host "SUCCESS: Added to license group -> $licenseGroupName" -ForegroundColor Green
        }
        else {

            Write-Host "WARNING: License group not found -> $licenseGroupName" -ForegroundColor Yellow
        }

    }
    catch {

        Write-Host "FAILED: $upn" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red

        $logEntry = "$(Get-Date),Onboarding,$upn,Failed,$($_.Exception.Message)"

        Add-Content -Path $logPath -Value $logEntry
    }
}

Write-Host ""
Write-Host "=== SCRIPT COMPLETE ===" -ForegroundColor Yellow
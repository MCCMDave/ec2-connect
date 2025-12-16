# EC2 SSH Connection Script
# Laedt Credentials aus credentials.ps1 (nicht im Repo!)
param(
    [string]$Action = "connect"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ============================================
# KONFIGURATION
# ============================================
$instanceId = "i-08aeaad1080557bea"
$region = "eu-central-1"
$sshUser = "ubuntu"
$hostName = "aws"

# Key-Pfad (automatisch fuer jeden User)
$keyPath = Join-Path $env:USERPROFILE ".ssh\team4_ec2.pem"
$sshConfigPath = Join-Path $env:USERPROFILE ".ssh\config"

# ============================================
# AWS CLI PFAD FINDEN
# ============================================
$awsCmd = Get-Command aws -ErrorAction SilentlyContinue
if (-not $awsCmd) {
    # Standard-Installationspfade pruefen
    $awsPaths = @(
        "C:\Program Files\Amazon\AWSCLIV2\aws.exe",
        "C:\Program Files (x86)\Amazon\AWSCLIV2\aws.exe",
        "$env:LOCALAPPDATA\Programs\Amazon\AWSCLIV2\aws.exe"
    )
    foreach ($p in $awsPaths) {
        if (Test-Path $p) {
            $awsCmd = $p
            break
        }
    }
}

if (-not $awsCmd) {
    Write-Host "AWS CLI nicht gefunden!" -ForegroundColor Red
    $install = Read-Host "Mit winget installieren? (j/n)"
    if ($install -match "^[jJyY]") {
        winget install Amazon.AWSCLI --accept-package-agreements --accept-source-agreements
        Write-Host "Bitte Terminal neu starten." -ForegroundColor Green
    }
    exit 1
}

# Wenn es ein CommandInfo-Objekt ist, den Pfad extrahieren
if ($awsCmd -is [System.Management.Automation.CommandInfo]) {
    $awsCmd = $awsCmd.Source
}

# ============================================
# CREDENTIALS LADEN
# ============================================
$credentialsFile = Join-Path $PSScriptRoot "credentials.ps1"

if (-not (Test-Path $credentialsFile)) {
    Write-Host "================================================" -ForegroundColor Red
    Write-Host "FEHLER: credentials.ps1 nicht gefunden!" -ForegroundColor Red
    Write-Host "================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Erstelle die Datei: credentials.ps1 (im gleichen Ordner)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Inhalt (aus Techstarter AWS Accounts kopieren):" -ForegroundColor Cyan
    Write-Host '  $env:AWS_ACCESS_KEY_ID = "ASIA..."'
    Write-Host '  $env:AWS_SECRET_ACCESS_KEY = "..."'
    Write-Host '  $env:AWS_SESSION_TOKEN = "..."'
    Write-Host ""
    Write-Host "Portal: https://techstarter-sandboxes.awsapps.com/start/#/?tab=accounts" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

# Credentials laden
. $credentialsFile

# ============================================
# KEY CHECK
# ============================================
if (-not (Test-Path $keyPath)) {
    Write-Host "SSH Key nicht gefunden: $keyPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Bitte Key-Datei speichern als:" -ForegroundColor Yellow
    Write-Host "  $keyPath" -ForegroundColor Cyan
    exit 1
}

# ============================================
# ACTIONS
# ============================================
if ($Action -eq "stop") {
    Write-Host "Stoppe Instance..." -ForegroundColor Yellow
    & $awsCmd ec2 stop-instances --instance-ids $instanceId --region $region | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Instance wird gestoppt" -ForegroundColor Green
    }
    exit $LASTEXITCODE
}

if ($Action -eq "status") {
    $info = & $awsCmd ec2 describe-instances `
        --instance-ids $instanceId `
        --region $region `
        --query 'Reservations[0].Instances[0].[State.Name,PublicIpAddress]' `
        --output text 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Fehler - Credentials abgelaufen?" -ForegroundColor Red
        Write-Host "Neue Credentials aus Techstarter AWS Accounts holen!" -ForegroundColor Yellow
        exit 1
    }

    $parts = $info -split "`t"
    Write-Host "Status: $($parts[0])" -ForegroundColor $(if ($parts[0] -eq "running") { "Green" } else { "Yellow" })
    Write-Host "IP:     $($parts[1])" -ForegroundColor White
    exit 0
}

# ============================================
# CONNECT
# ============================================
try {
    $instanceInfo = & $awsCmd ec2 describe-instances `
        --instance-ids $instanceId `
        --region $region `
        --query 'Reservations[0].Instances[0].[State.Name,PublicIpAddress]' `
        --output text 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Host "AWS Fehler - Credentials abgelaufen?" -ForegroundColor Red
        Write-Host ""
        Write-Host "Neue Credentials aus Techstarter AWS Accounts holen:" -ForegroundColor Yellow
        Write-Host "1. https://techstarter-sandboxes.awsapps.com/start/#/?tab=accounts" -ForegroundColor Cyan
        Write-Host "2. Account auswaehlen -> Command line or programmatic access" -ForegroundColor Cyan
        Write-Host "3. Credentials in credentials.ps1 hinterlegen" -ForegroundColor Cyan
        exit 1
    }

    $info = $instanceInfo -split "`t"
    $state = $info[0]
    $publicIp = $info[1]

    if ($state -ne "running") {
        Write-Host "Starte Instance..." -ForegroundColor Yellow
        & $awsCmd ec2 start-instances --instance-ids $instanceId --region $region | Out-Null

        $maxWait = 90
        $waited = 0
        while ($waited -lt $maxWait) {
            Start-Sleep -Seconds 5
            $waited += 5
            Write-Host "." -NoNewline -ForegroundColor Gray

            $currentState = & $awsCmd ec2 describe-instances `
                --instance-ids $instanceId `
                --region $region `
                --query 'Reservations[0].Instances[0].State.Name' `
                --output text

            if ($currentState -eq "running") {
                Write-Host ""
                Start-Sleep -Seconds 10
                $publicIp = & $awsCmd ec2 describe-instances `
                    --instance-ids $instanceId `
                    --region $region `
                    --query 'Reservations[0].Instances[0].PublicIpAddress' `
                    --output text
                Write-Host "Gestartet!" -ForegroundColor Green
                break
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($publicIp) -or $publicIp -eq "None") {
        Write-Host "Keine IP gefunden" -ForegroundColor Red
        exit 1
    }

    Write-Host "IP: $publicIp" -ForegroundColor Cyan

} catch {
    Write-Host "Fehler: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# ============================================
# SSH CONFIG UPDATE
# ============================================
try {
    $sshDir = Split-Path $sshConfigPath -Parent
    if (-not (Test-Path $sshDir)) {
        New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
    }

    $configContent = if (Test-Path $sshConfigPath) { Get-Content -Path $sshConfigPath -Raw } else { "" }

    if ($configContent -match "Host\s+$hostName\s") {
        $lines = $configContent -split "`r?`n"
        $inHostBlock = $false
        $updatedLines = @()

        foreach ($line in $lines) {
            if ($line -match "^\s*Host\s+$hostName\s*$") {
                $inHostBlock = $true
                $updatedLines += $line
            } elseif ($inHostBlock -and $line -match "^\s*HostName\s+") {
                $updatedLines += "    HostName $publicIp"
                $inHostBlock = $false
            } elseif ($inHostBlock -and $line -match "^\s*Host\s+") {
                $inHostBlock = $false
                $updatedLines += $line
            } else {
                $updatedLines += $line
            }
        }

        Set-Content -Path $sshConfigPath -Value ($updatedLines -join "`n") -Encoding UTF8
    } else {
        $newBlock = @"

Host $hostName
    HostName $publicIp
    User $sshUser
    IdentityFile $keyPath
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
"@
        Add-Content -Path $sshConfigPath -Value $newBlock -Encoding UTF8
    }
} catch {
    Write-Host "SSH Config Fehler (ignoriert)" -ForegroundColor Yellow
}

# ============================================
# CONNECT
# ============================================
Write-Host "Verbinde... (ssh $hostName)" -ForegroundColor Gray
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $hostName

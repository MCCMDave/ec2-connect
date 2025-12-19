# EC2 SSH Connection Script - Multilingual (DE/EN)
# Supports multiple instances, interactive credentials, SSH config
param(
    [string]$Action = "",
    [string]$Instance = "",
    [string]$Lang = ""
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ============================================
# LANGUAGE / SPRACHE
# ============================================
if (-not $Lang) {
    $Lang = if ((Get-Culture).TwoLetterISOLanguageName -eq "de") { "de" } else { "en" }
}

$msg = @{
    "de" = @{
        "title" = "EC2 Instance Manager"
        "menu_connect" = "Verbinden"
        "menu_start" = "Starten"
        "menu_stop" = "Stoppen"
        "menu_status" = "Status"
        "menu_all_status" = "Alle Status"
        "menu_stop_all" = "Alle stoppen"
        "menu_exit" = "Beenden"
        "select_instance" = "Instance waehlen"
        "select_action" = "Aktion waehlen"
        "no_instances" = "Keine Instances konfiguriert!"
        "aws_not_found" = "AWS CLI nicht gefunden!"
        "install_winget" = "Mit winget installieren? (j/n)"
        "restart_terminal" = "Bitte Terminal neu starten."
        "creds_not_found" = "Credentials nicht gefunden!"
        "creds_enter" = "Credentials jetzt eingeben? (j/n)"
        "creds_saved" = "Credentials gespeichert!"
        "creds_retry" = "Versuche erneut..."
        "key_not_found" = "SSH Key nicht gefunden"
        "key_save" = "Bitte Key-Datei speichern als"
        "stopping" = "Stoppe Instance..."
        "stopped" = "Instance wird gestoppt"
        "starting" = "Starte Instance..."
        "started" = "Gestartet!"
        "connecting" = "Verbinde..."
        "no_ip" = "Keine IP gefunden"
        "error" = "Fehler"
        "creds_expired" = "Credentials abgelaufen!"
        "creds_renew" = "Neue Credentials eingeben? (j/n)"
        "status" = "Status"
        "ip" = "IP"
        "exiting" = "Beenden in"
        "press_key" = "Druecke Taste..."
        "back" = "Zurueck"
    }
    "en" = @{
        "title" = "EC2 Instance Manager"
        "menu_connect" = "Connect"
        "menu_start" = "Start"
        "menu_stop" = "Stop"
        "menu_status" = "Status"
        "menu_all_status" = "All Status"
        "menu_stop_all" = "Stop All"
        "menu_exit" = "Exit"
        "select_instance" = "Select Instance"
        "select_action" = "Select Action"
        "no_instances" = "No instances configured!"
        "aws_not_found" = "AWS CLI not found!"
        "install_winget" = "Install via winget? (y/n)"
        "restart_terminal" = "Please restart terminal."
        "creds_not_found" = "Credentials not found!"
        "creds_enter" = "Enter credentials now? (y/n)"
        "creds_saved" = "Credentials saved!"
        "creds_retry" = "Retrying..."
        "key_not_found" = "SSH Key not found"
        "key_save" = "Please save key file as"
        "stopping" = "Stopping instance..."
        "stopped" = "Instance stopping"
        "starting" = "Starting instance..."
        "started" = "Started!"
        "connecting" = "Connecting..."
        "no_ip" = "No IP found"
        "error" = "Error"
        "creds_expired" = "Credentials expired!"
        "creds_renew" = "Enter new credentials? (y/n)"
        "status" = "Status"
        "ip" = "IP"
        "exiting" = "Exiting in"
        "press_key" = "Press any key..."
        "back" = "Back"
    }
}

function T($key) { return $msg[$Lang][$key] }

# ============================================
# INSTANCE CONFIGURATION
# ============================================
# Add your instances here:
$instances = @(
    @{
        Name = "MyServer"
        Id = "i-0123456789abcdef0"
        Region = "eu-central-1"
        User = "ubuntu"
        KeyFile = "my-key.pem"
        SshAlias = "myserver"
    }
    # Add more instances:
    # @{
    #     Name = "Production"
    #     Id = "i-0abc123def456"
    #     Region = "eu-west-1"
    #     User = "ec2-user"
    #     KeyFile = "prod.pem"
    #     SshAlias = "prod"
    # }
)

$sshConfigPath = Join-Path $env:USERPROFILE ".ssh\config"

# ============================================
# AWS CLI PATH
# ============================================
function Get-AwsCmd {
    $awsCmd = Get-Command aws -ErrorAction SilentlyContinue
    if (-not $awsCmd) {
        $awsPaths = @(
            "C:\Program Files\Amazon\AWSCLIV2\aws.exe",
            "C:\Program Files (x86)\Amazon\AWSCLIV2\aws.exe",
            "$env:LOCALAPPDATA\Programs\Amazon\AWSCLIV2\aws.exe"
        )
        foreach ($p in $awsPaths) {
            if (Test-Path $p) { return $p }
        }
        return $null
    }
    if ($awsCmd -is [System.Management.Automation.CommandInfo]) {
        return $awsCmd.Source
    }
    return $awsCmd
}

$awsCmd = Get-AwsCmd
if (-not $awsCmd) {
    Write-Host (T "aws_not_found") -ForegroundColor Red
    $install = Read-Host (T "install_winget")
    if ($install -match "^[jJyY]") {
        winget install Amazon.AWSCLI --accept-package-agreements --accept-source-agreements
        Write-Host (T "restart_terminal") -ForegroundColor Green
    }
    exit 1
}

# ============================================
# CREDENTIALS
# ============================================
function Load-Credentials {
    $credsPs1 = Join-Path $PSScriptRoot "credentials.ps1"
    $credsTxt = Join-Path $PSScriptRoot "credentials.txt"

    if (Test-Path $credsPs1) {
        . $credsPs1
        return $true
    }

    if (Test-Path $credsTxt) {
        Get-Content $credsTxt | ForEach-Object {
            if ($_ -match '^\s*(AWS_[A-Z_]+)\s*=\s*"?([^"]+)"?\s*$') {
                [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
            }
        }
        return $true
    }

    return $false
}

function Enter-Credentials {
    Write-Host ""
    Write-Host "AWS_ACCESS_KEY_ID: " -NoNewline -ForegroundColor Gray
    $accessKey = Read-Host
    Write-Host "AWS_SECRET_ACCESS_KEY: " -NoNewline -ForegroundColor Gray
    $secretKey = Read-Host
    Write-Host "AWS_SESSION_TOKEN: " -NoNewline -ForegroundColor Gray
    $sessionToken = Read-Host

    $credsTxt = Join-Path $PSScriptRoot "credentials.txt"
    $content = @"
AWS_ACCESS_KEY_ID=$accessKey
AWS_SECRET_ACCESS_KEY=$secretKey
AWS_SESSION_TOKEN=$sessionToken
"@
    Set-Content -Path $credsTxt -Value $content -Encoding UTF8
    Write-Host ""
    Write-Host (T "creds_saved") -ForegroundColor Green

    # Reload immediately
    Load-Credentials | Out-Null
}

# Initial credential check
if (-not (Load-Credentials)) {
    Write-Host "================================================" -ForegroundColor Yellow
    Write-Host (T "creds_not_found") -ForegroundColor Yellow
    Write-Host "================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Portal: https://aws.amazon.com/console" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "$(T 'creds_enter'): " -NoNewline -ForegroundColor White
    $answer = Read-Host

    if ($answer -match "^[jJyY]") {
        Enter-Credentials
    } else {
        exit 1
    }
}

# ============================================
# HELPER FUNCTIONS
# ============================================
function Exit-WithTimer {
    for ($i = 3; $i -gt 0; $i--) {
        Write-Host "$(T 'exiting') $i..." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
    }
    exit 0
}

function Show-Menu {
    param([string]$Title, [array]$Options, [bool]$ShowBack = $false)

    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "  [$($i + 1)] $($Options[$i])" -ForegroundColor White
    }

    if ($ShowBack) {
        Write-Host ""
        Write-Host "  [B] $(T 'back')" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "  [0] $(T 'menu_exit')" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "----------------------------------------" -ForegroundColor DarkGray

    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    return $key.Character
}

function Get-InstanceStatus {
    param($Inst)

    try {
        $info = & $awsCmd ec2 describe-instances `
            --instance-ids $Inst.Id `
            --region $Inst.Region `
            --query 'Reservations[0].Instances[0].[State.Name,PublicIpAddress]' `
            --output text 2>&1

        if ($LASTEXITCODE -ne 0) {
            return @{ State = "error"; IP = "N/A" }
        }

        $parts = $info -split "`t"
        return @{ State = $parts[0]; IP = if ($parts[1] -eq "None") { "N/A" } else { $parts[1] } }
    } catch {
        return @{ State = "error"; IP = "N/A" }
    }
}

function Start-Instance {
    param($Inst)

    Write-Host (T "starting") -ForegroundColor Yellow
    & $awsCmd ec2 start-instances --instance-ids $Inst.Id --region $Inst.Region | Out-Null

    $maxWait = 90
    $waited = 0
    while ($waited -lt $maxWait) {
        Start-Sleep -Seconds 5
        $waited += 5
        Write-Host "." -NoNewline -ForegroundColor Gray

        $status = Get-InstanceStatus $Inst
        if ($status.State -eq "running") {
            Write-Host ""
            Start-Sleep -Seconds 10
            return (Get-InstanceStatus $Inst)
        }
    }
    return $null
}

function Stop-Instance {
    param($Inst)

    Write-Host (T "stopping") -ForegroundColor Yellow
    & $awsCmd ec2 stop-instances --instance-ids $Inst.Id --region $Inst.Region | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host (T "stopped") -ForegroundColor Green
    }
}

function Update-SshConfig {
    param($Inst, $IP)

    $keyPath = Join-Path $env:USERPROFILE ".ssh\$($Inst.KeyFile)"
    $sshDir = Split-Path $sshConfigPath -Parent

    if (-not (Test-Path $sshDir)) {
        New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
    }

    $configContent = if (Test-Path $sshConfigPath) { Get-Content -Path $sshConfigPath -Raw } else { "" }
    $hostName = $Inst.SshAlias

    if ($configContent -match "Host\s+$hostName\s") {
        $lines = $configContent -split "`r?`n"
        $inHostBlock = $false
        $updatedLines = @()

        foreach ($line in $lines) {
            if ($line -match "^\s*Host\s+$hostName\s*$") {
                $inHostBlock = $true
                $updatedLines += $line
            } elseif ($inHostBlock -and $line -match "^\s*HostName\s+") {
                $updatedLines += "    HostName $IP"
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
    HostName $IP
    User $($Inst.User)
    IdentityFile $keyPath
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
"@
        Add-Content -Path $sshConfigPath -Value $newBlock -Encoding UTF8
    }
}

function Connect-ToInstance {
    param($Inst)

    $keyPath = Join-Path $env:USERPROFILE ".ssh\$($Inst.KeyFile)"

    if (-not (Test-Path $keyPath)) {
        Write-Host "$(T 'key_not_found'): $keyPath" -ForegroundColor Red
        Write-Host ""
        Write-Host "$(T 'key_save'):" -ForegroundColor Yellow
        Write-Host "  $keyPath" -ForegroundColor Cyan
        Write-Host ""
        Write-Host (T "press_key") -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }

    $status = Get-InstanceStatus $Inst

    # Credential error - offer renewal and retry
    if ($status.State -eq "error") {
        Write-Host (T "creds_expired") -ForegroundColor Red
        Write-Host ""
        Write-Host "$(T 'creds_renew'): " -NoNewline -ForegroundColor White
        $answer = Read-Host

        if ($answer -match "^[jJyY]") {
            Enter-Credentials
            Write-Host (T "creds_retry") -ForegroundColor Yellow
            Start-Sleep -Seconds 1

            # Retry connection
            $status = Get-InstanceStatus $Inst
            if ($status.State -eq "error") {
                Write-Host (T "error") -ForegroundColor Red
                Write-Host ""
                Write-Host (T "press_key") -ForegroundColor Gray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
        } else {
            return
        }
    }

    if ($status.State -ne "running") {
        $status = Start-Instance $Inst
        if (-not $status) {
            Write-Host (T "error") -ForegroundColor Red
            return
        }
        Write-Host (T "started") -ForegroundColor Green
    }

    if ($status.IP -eq "N/A") {
        Write-Host (T "no_ip") -ForegroundColor Red
        return
    }

    Write-Host "$(T 'ip'): $($status.IP)" -ForegroundColor Cyan
    Update-SshConfig $Inst $status.IP

    Write-Host "$(T 'connecting') (ssh $($Inst.SshAlias))" -ForegroundColor Gray
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $Inst.SshAlias
}

# ============================================
# DIRECT ACTION MODE
# ============================================
if ($Action -and $Instance) {
    $inst = $instances | Where-Object { $_.Name -eq $Instance -or $_.SshAlias -eq $Instance }
    if (-not $inst) {
        Write-Host "Instance not found: $Instance" -ForegroundColor Red
        exit 1
    }

    switch ($Action.ToLower()) {
        "connect" { Connect-ToInstance $inst }
        "start" { Start-Instance $inst | Out-Null; Write-Host (T "started") -ForegroundColor Green }
        "stop" { Stop-Instance $inst }
        "status" {
            $s = Get-InstanceStatus $inst
            Write-Host "$(T 'status'): $($s.State)" -ForegroundColor $(if ($s.State -eq "running") { "Green" } else { "Yellow" })
            Write-Host "$(T 'ip'):     $($s.IP)" -ForegroundColor White
        }
    }
    exit 0
}

if ($Action -eq "status" -and -not $Instance) {
    foreach ($inst in $instances) {
        $s = Get-InstanceStatus $inst
        $color = switch ($s.State) { "running" { "Green" } "stopped" { "Yellow" } default { "Red" } }
        Write-Host "$($inst.Name): $($s.State) ($($s.IP))" -ForegroundColor $color
    }
    exit 0
}

# ============================================
# INTERACTIVE MENU
# ============================================
if ($instances.Count -eq 0) {
    Write-Host (T "no_instances") -ForegroundColor Red
    exit 1
}

# Single instance = direct action menu
if ($instances.Count -eq 1) {
    $selectedInstance = $instances[0]

    while ($true) {
        $actionOptions = @(
            (T "menu_connect"),
            (T "menu_status"),
            (T "menu_stop")
        )

        $choice = Show-Menu "$($selectedInstance.Name)" $actionOptions

        switch ($choice) {
            '0' { Exit-WithTimer }
            '1' { Connect-ToInstance $selectedInstance; break }
            '2' {
                $s = Get-InstanceStatus $selectedInstance
                Write-Host ""
                Write-Host "$(T 'status'): $($s.State)" -ForegroundColor $(if ($s.State -eq "running") { "Green" } else { "Yellow" })
                Write-Host "$(T 'ip'):     $($s.IP)" -ForegroundColor White
                Write-Host ""
                Read-Host "ENTER"
            }
            '3' {
                Stop-Instance $selectedInstance
                Write-Host ""
                Write-Host (T "press_key") -ForegroundColor Gray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
    }
    exit 0
}

# Multiple instances = instance selection menu
while ($true) {
    $instanceNames = $instances | ForEach-Object { $_.Name }
    $instanceNames += (T "menu_all_status")
    $instanceNames += (T "menu_stop_all")

    $choice = Show-Menu (T "select_instance") $instanceNames

    if ($choice -eq '0') { Exit-WithTimer }

    $idx = [int]::Parse($choice) - 1

    # All Status
    if ($idx -eq $instances.Count) {
        Write-Host ""
        foreach ($inst in $instances) {
            $s = Get-InstanceStatus $inst
            $color = switch ($s.State) { "running" { "Green" } "stopped" { "Yellow" } default { "Red" } }
            Write-Host "$($inst.Name): $($s.State) ($($s.IP))" -ForegroundColor $color
        }
        Write-Host ""
        Read-Host "ENTER"
        continue
    }

    # Stop All
    if ($idx -eq $instances.Count + 1) {
        foreach ($inst in $instances) {
            Write-Host "$($inst.Name): " -NoNewline
            Stop-Instance $inst
        }
        Write-Host ""
        Write-Host (T "press_key") -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        continue
    }

    if ($idx -ge 0 -and $idx -lt $instances.Count) {
        $selectedInstance = $instances[$idx]

        while ($true) {
            $actionOptions = @(
                (T "menu_connect"),
                (T "menu_stop")
            )

            $actionChoice = Show-Menu "$($selectedInstance.Name)" $actionOptions $true

            switch ($actionChoice) {
                '0' { Exit-WithTimer }
                'b' { break }
                'B' { break }
                '1' { Connect-ToInstance $selectedInstance; break }
                '2' {
                    Stop-Instance $selectedInstance
                    Write-Host ""
                    Write-Host (T "press_key") -ForegroundColor Gray
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
            }

            if ($actionChoice -match '^[bB]$') { break }
        }
    }
}

# AWS EC2 SSH Connection Script
# Verbindet automatisch zu EC2, startet Instance bei Bedarf, aktualisiert SSH Config
param(
    [string]$Action = "connect",
    [string]$SshAlias = ""  # Optional: SSH Config Alias (z.B. "aws", "ec2", "myserver")
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ============================================
# KONFIGURATION - Hier anpassen!
# ============================================
$instanceId = "INSTANCE-ID-HIER"           # z.B. i-0abc123def456
$region = "eu-west-1"                       # AWS Region
$keyPath = "~/.ssh/your-key.pem"           # Pfad zum SSH Key
$sshUser = "ubuntu"                         # SSH User (ubuntu, ec2-user, admin)
$defaultAlias = "ec2"                       # Standard SSH-Alias wenn keiner angegeben

# SSH Config
$sshConfigPath = "$env:USERPROFILE\.ssh\config"
$hostName = if ($SshAlias) { $SshAlias } else { $defaultAlias }

# ============================================
# AWS CLI CHECK
# ============================================
function Test-AwsCli {
    $awsPath = Get-Command aws -ErrorAction SilentlyContinue
    if (-not $awsPath) {
        Write-Host "AWS CLI nicht gefunden!" -ForegroundColor Red
        Write-Host ""
        $install = Read-Host "Mit winget installieren? (j/n)"
        if ($install -eq "j" -or $install -eq "J" -or $install -eq "y" -or $install -eq "Y") {
            Write-Host "Installiere AWS CLI..." -ForegroundColor Yellow
            winget install Amazon.AWSCLI --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -eq 0) {
                Write-Host "AWS CLI installiert! Bitte Terminal neu starten." -ForegroundColor Green
            } else {
                Write-Host "Installation fehlgeschlagen. Manuell: https://aws.amazon.com/cli/" -ForegroundColor Red
            }
        } else {
            Write-Host "Abgebrochen. AWS CLI erforderlich: https://aws.amazon.com/cli/" -ForegroundColor Yellow
        }
        exit 1
    }
}

# AWS CLI pruefen
Test-AwsCli

# ============================================
# STOP ACTION
# ============================================
if ($Action -eq "stop") {
    Write-Host "Stoppe Instance $instanceId..." -ForegroundColor Yellow
    aws ec2 stop-instances --instance-ids $instanceId --region $region | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Instance wird gestoppt (spart Kosten!)" -ForegroundColor Green
    } else {
        Write-Host "Fehler beim Stoppen" -ForegroundColor Red
    }
    exit $LASTEXITCODE
}

# ============================================
# STATUS ACTION
# ============================================
if ($Action -eq "status") {
    $info = aws ec2 describe-instances `
        --instance-ids $instanceId `
        --region $region `
        --query 'Reservations[0].Instances[0].[State.Name,PublicIpAddress,InstanceType]' `
        --output text

    $parts = $info -split "`t"
    Write-Host "Instance: $instanceId" -ForegroundColor Cyan
    Write-Host "Status:   $($parts[0])" -ForegroundColor $(if ($parts[0] -eq "running") { "Green" } else { "Yellow" })
    Write-Host "IP:       $($parts[1])" -ForegroundColor White
    Write-Host "Typ:      $($parts[2])" -ForegroundColor Gray
    exit 0
}

# ============================================
# CONNECT (DEFAULT)
# ============================================
try {
    $instanceInfo = aws ec2 describe-instances `
        --instance-ids $instanceId `
        --region $region `
        --query 'Reservations[0].Instances[0].[State.Name,PublicIpAddress]' `
        --output text 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Host "AWS Fehler: $instanceInfo" -ForegroundColor Red
        exit 1
    }

    $info = $instanceInfo -split "`t"
    $state = $info[0]
    $publicIp = $info[1]

    # Starte Instance automatisch wenn nicht running
    if ($state -ne "running") {
        Write-Host "Starte Instance..." -ForegroundColor Yellow

        $startResult = aws ec2 start-instances --instance-ids $instanceId --region $region 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Fehler beim Starten: $startResult" -ForegroundColor Red
            Write-Host "Starte manuell: https://$region.console.aws.amazon.com/ec2" -ForegroundColor Cyan
            exit 1
        }

        # Warte auf Start
        $maxWait = 90
        $waited = 0
        while ($waited -lt $maxWait) {
            Start-Sleep -Seconds 5
            $waited += 5
            Write-Host "." -NoNewline -ForegroundColor Gray

            $currentState = aws ec2 describe-instances `
                --instance-ids $instanceId `
                --region $region `
                --query 'Reservations[0].Instances[0].State.Name' `
                --output text

            if ($currentState -eq "running") {
                Write-Host ""
                Start-Sleep -Seconds 10  # SSH braucht noch paar Sekunden
                $publicIp = aws ec2 describe-instances `
                    --instance-ids $instanceId `
                    --region $region `
                    --query 'Reservations[0].Instances[0].PublicIpAddress' `
                    --output text
                Write-Host "Instance gestartet!" -ForegroundColor Green
                break
            }
        }

        if ($waited -ge $maxWait) {
            Write-Host "`nTimeout beim Warten auf Instance" -ForegroundColor Red
            exit 1
        }
    }

    if ([string]::IsNullOrWhiteSpace($publicIp) -or $publicIp -eq "None") {
        Write-Host "Keine oeffentliche IP-Adresse gefunden" -ForegroundColor Red
        exit 1
    }

    Write-Host "IP: $publicIp | SSH-Alias: $hostName" -ForegroundColor Cyan

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

    if (-not (Test-Path $sshConfigPath)) {
        $newConfig = @"
Host $hostName
    HostName $publicIp
    User $sshUser
    IdentityFile $keyPath
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
"@
        Set-Content -Path $sshConfigPath -Value $newConfig -Encoding UTF8
        Write-Host "SSH Config erstellt: ssh $hostName" -ForegroundColor Green
    } else {
        $configContent = Get-Content -Path $sshConfigPath -Raw

        if ($configContent -match "Host\s+$hostName\s") {
            # Host existiert - IP aktualisieren
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
            # Neuen Host-Block hinzufuegen
            $newBlock = @"

Host $hostName
    HostName $publicIp
    User $sshUser
    IdentityFile $keyPath
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
"@
            Add-Content -Path $sshConfigPath -Value $newBlock -Encoding UTF8
            Write-Host "SSH Config erweitert: ssh $hostName" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "SSH Config Fehler: $($_.Exception.Message)" -ForegroundColor Yellow
    # Weiter ohne Config-Update
}

# ============================================
# SSH CONNECT
# ============================================
Write-Host "Verbinde..." -ForegroundColor Gray
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $hostName

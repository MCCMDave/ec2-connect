# AWS EC2 SSH Connection Script
param([string]$Action = "connect")

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Konfiguration
$instanceId = "i-0552f93f7e12beaa7"
$region = "eu-central-1"
$sshConfigPath = "$env:USERPROFILE\.ssh\config"
$hostName = "aws"

# Stop-Aktion
if ($Action -eq "stop") {
    Write-Host "Stoppe Instance..." -ForegroundColor Yellow
    aws ec2 stop-instances --instance-ids $instanceId --region $region | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Instance wird gestoppt (spart Kosten!)" -ForegroundColor Green
    } else {
        Write-Host "Fehler beim Stoppen" -ForegroundColor Red
    }
    exit $LASTEXITCODE
}

# Hole Instance-Status und IP
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
            Write-Host "Starte manuell: https://eu-central-1.console.aws.amazon.com/ec2" -ForegroundColor Cyan
            exit 1
        }
        
        # Warte auf Start
        $maxWait = 60
        $waited = 0
        while ($waited -lt $maxWait) {
            Start-Sleep -Seconds 5
            $waited += 5
            
            $currentState = aws ec2 describe-instances `
                --instance-ids $instanceId `
                --region $region `
                --query 'Reservations[0].Instances[0].State.Name' `
                --output text
            
            if ($currentState -eq "running") {
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
            Write-Host "Timeout" -ForegroundColor Red
            exit 1
        }
    }

    if ([string]::IsNullOrWhiteSpace($publicIp) -or $publicIp -eq "None") {
        Write-Host "Keine IP-Adresse gefunden" -ForegroundColor Red
        exit 1
    }

} catch {
    Write-Host "Fehler: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Aktualisiere SSH Config
try {
    if (-not (Test-Path $sshConfigPath)) {
        $newConfig = @"
Host $hostName
    HostName $publicIp
    User ubuntu
    IdentityFile ~/.ssh/ec2-key.pem
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
"@
        Set-Content -Path $sshConfigPath -Value $newConfig -Encoding UTF8
    } else {
        $configContent = Get-Content -Path $sshConfigPath -Raw
        
        if ($configContent -match "Host\s+$hostName\s") {
            $pattern = "(Host\s+$hostName\s+.*?HostName\s+)\S+(\s)"
            $replacement = "`${1}$publicIp`$2"
            $newContent = $configContent -replace $pattern, $replacement
            
            if ($newContent -eq $configContent) {
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
                
                $newContent = $updatedLines -join "`n"
            }
            
            Set-Content -Path $sshConfigPath -Value $newContent -Encoding UTF8
        } else {
            $newBlock = @"

Host $hostName
    HostName $publicIp
    User ubuntu
    IdentityFile ~/.ssh/ec2-key.pem
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
"@
            Add-Content -Path $sshConfigPath -Value $newBlock -Encoding UTF8
        }
    }
} catch {
    Write-Host "Config-Fehler: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Verbinde (ohne Host-Key-Abfrage)
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $hostName
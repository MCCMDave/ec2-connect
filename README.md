# EC2 Connect

Auto-Start und SSH-Verbindung zu EC2 Instanzen.

## Setup

1. Key-Datei nach `~/.ssh/ec2-key.pem` kopieren
2. Instance-ID in `connect-aws.ps1` anpassen (Zeile 8)

## Nutzung

```batch
connect-aws.bat
```

**Was passiert:**
- Prüft ob EC2 läuft, startet automatisch falls nicht
- Aktualisiert SSH-Config mit aktueller IP
- Verbindet via SSH

## Konfiguration

In `connect-aws.ps1`:
```powershell
$instanceId = "i-0552f93f7e12beaa7"  # Deine Instance-ID
$region = "eu-central-1"
$hostName = "aws"                     # SSH alias
```

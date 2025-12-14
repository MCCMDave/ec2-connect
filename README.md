# EC2 Connect

Auto-Start und SSH-Verbindung zu EC2 Instanzen.
Auto-start and SSH connection to EC2 instances.

---

## Setup

**DE:** Key-Datei nach `~/.ssh/ec2-key.pem` kopieren, Instance-ID in `connect-aws.ps1` anpassen (Zeile 8)

**EN:** Copy key file to `~/.ssh/ec2-key.pem`, adjust Instance-ID in `connect-aws.ps1` (line 8)

## Nutzung / Usage

```batch
connect-aws.bat           # Verbinden / Connect
connect-aws.bat stop      # Instanz stoppen / Stop instance
```

**DE:** Prüft ob EC2 läuft, startet automatisch falls nicht, aktualisiert SSH-Config, verbindet via SSH.

**EN:** Checks if EC2 is running, auto-starts if not, updates SSH config, connects via SSH.

## Konfiguration / Configuration

```powershell
$instanceId = "i-0552f93f7e12beaa7"  # Deine Instance-ID / Your Instance-ID
$region = "eu-central-1"
$hostName = "aws"                     # SSH alias
```

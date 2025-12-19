# EC2 Connect

PowerShell script for seamless AWS EC2 SSH connections with automatic instance management.

**[🇩🇪 Deutsche Version](#deutsch)** | **[🇬🇧 English Version](#english)**

---

## English

### Features

- **Multi-Instance:** Manage multiple EC2 instances from one menu
- **Auto-Start:** Automatically starts stopped instances
- **Dynamic IP:** Updates SSH config with current public IP
- **SSH Alias:** Custom SSH alias support (`ssh myserver`)
- **Bilingual:** Auto-detects language (DE/EN)
- **Interactive Credentials:** Enter credentials on first start (no manual file creation)
- **Credential Renewal:** Re-enter expired credentials without restarting
- **AWS CLI Check:** Prompts to install via winget if missing
- **Exit Timer:** 3-second countdown before exit (Option 0)

### Setup

1. Copy your `.pem` key file to `~/.ssh/`
2. Edit instance configuration in `connect-ec2.ps1`
3. Run the script - credentials are entered interactively on first start

### Instance Configuration

```powershell
$instances = @(
    @{
        Name = "Production"
        Id = "i-0abc123def456"
        Region = "eu-central-1"
        User = "ubuntu"
        KeyFile = "mykey.pem"
        SshAlias = "prod"
    }
    @{
        Name = "Staging"
        Id = "i-0def789abc123"
        Region = "eu-west-1"
        User = "ec2-user"
        KeyFile = "staging.pem"
        SshAlias = "stage"
    }
)
```

### Usage

**Interactive Menu:**
```powershell
.\connect-ec2.ps1              # Opens instance menu
```

**Command Line:**
```powershell
.\connect-ec2.ps1 -Action status                    # All instances status
.\connect-ec2.ps1 -Action connect -Instance prod    # Connect to "prod"
.\connect-ec2.ps1 -Action stop -Instance prod       # Stop "prod"
```

**After first connect:**
```bash
ssh prod     # Direct SSH using alias
```

### Credentials

**Interactive Entry (Recommended):**
On first start, the script prompts for credentials:
```
AWS_ACCESS_KEY_ID: ASIA...
AWS_SECRET_ACCESS_KEY: ...
AWS_SESSION_TOKEN: ...
```
Credentials are saved to `credentials.txt` and the menu continues automatically.

**If credentials expire:** The script detects expired credentials and offers immediate re-entry without restart.

**Manual file creation (optional):**
```
AWS_ACCESS_KEY_ID=ASIA...
AWS_SECRET_ACCESS_KEY=...
AWS_SESSION_TOKEN=...
```

**Security Note:** Credentials file is in `.gitignore`. They are only loaded into the current process environment.

### Stop Backend on Instance

To stop a running backend service on your EC2 instance:

```bash
# Connect first
ssh prod

# Option 1: Stop specific process
pkill -f "python main.py"
pkill -f "uvicorn"
pkill -f "node server.js"

# Option 2: Stop by port
sudo fuser -k 8000/tcp    # Kills process on port 8000

# Option 3: Stop systemd service
sudo systemctl stop myapp
sudo systemctl status myapp

# Option 4: Docker
docker stop container_name
docker ps                  # List running containers
```

### Requirements

- PowerShell 5.1+
- AWS CLI (script offers winget installation if missing)
- SSH client

---

## Deutsch

### Features

- **Multi-Instance:** Mehrere EC2 Instanzen über ein Menü verwalten
- **Auto-Start:** Startet gestoppte Instanzen automatisch
- **Dynamische IP:** Aktualisiert SSH Config mit aktueller IP
- **SSH Alias:** Eigene SSH Aliase (`ssh meinserver`)
- **Zweisprachig:** Erkennt Sprache automatisch (DE/EN)
- **Interaktive Credentials:** Eingabe beim ersten Start (keine manuelle Dateierstellung)
- **Credential-Erneuerung:** Abgelaufene Credentials direkt neu eingeben ohne Neustart
- **AWS CLI Check:** Bietet winget Installation an falls fehlend
- **Exit Timer:** 3-Sekunden Countdown beim Beenden (Option 0)

### Einrichtung

1. `.pem` Key-Datei nach `~/.ssh/` kopieren
2. Instanz-Konfiguration in `connect-ec2.ps1` anpassen
3. Script starten - Credentials werden beim ersten Start interaktiv abgefragt

### Instanz-Konfiguration

```powershell
$instances = @(
    @{
        Name = "Produktion"
        Id = "i-0abc123def456"
        Region = "eu-central-1"
        User = "ubuntu"
        KeyFile = "meinkey.pem"
        SshAlias = "prod"
    }
    @{
        Name = "Staging"
        Id = "i-0def789abc123"
        Region = "eu-west-1"
        User = "ec2-user"
        KeyFile = "staging.pem"
        SshAlias = "stage"
    }
)
```

### Verwendung

**Interaktives Menü:**
```powershell
.\connect-ec2.ps1              # Öffnet Instanz-Menü
```

**Kommandozeile:**
```powershell
.\connect-ec2.ps1 -Action status                    # Status aller Instanzen
.\connect-ec2.ps1 -Action connect -Instance prod    # Mit "prod" verbinden
.\connect-ec2.ps1 -Action stop -Instance prod       # "prod" stoppen
```

**Nach erstem Connect:**
```bash
ssh prod     # Direkter SSH mit Alias
```

### Credentials

**Interaktive Eingabe (Empfohlen):**
Beim ersten Start fragt das Script nach Credentials:
```
AWS_ACCESS_KEY_ID: ASIA...
AWS_SECRET_ACCESS_KEY: ...
AWS_SESSION_TOKEN: ...
```
Credentials werden in `credentials.txt` gespeichert und das Menü startet automatisch.

**Bei abgelaufenen Credentials:** Das Script erkennt abgelaufene Credentials und bietet direkte Neueingabe ohne Neustart.

**Manuelle Dateierstellung (optional):**
```
AWS_ACCESS_KEY_ID=ASIA...
AWS_SECRET_ACCESS_KEY=...
AWS_SESSION_TOKEN=...
```

**Sicherheitshinweis:** Credentials-Datei ist in `.gitignore`. Sie werden nur in die aktuelle Prozess-Umgebung geladen.

### Backend auf Instanz beenden

Um einen laufenden Backend-Service auf der EC2 Instanz zu stoppen:

```bash
# Zuerst verbinden
ssh prod

# Option 1: Spezifischen Prozess stoppen
pkill -f "python main.py"
pkill -f "uvicorn"
pkill -f "node server.js"

# Option 2: Nach Port stoppen
sudo fuser -k 8000/tcp    # Beendet Prozess auf Port 8000

# Option 3: systemd Service stoppen
sudo systemctl stop myapp
sudo systemctl status myapp

# Option 4: Docker
docker stop container_name
docker ps                  # Laufende Container anzeigen
```

### Anforderungen

- PowerShell 5.1+
- AWS CLI (Script bietet winget Installation an falls fehlend)
- SSH Client

---

*Made for quick EC2 access without remembering IPs*

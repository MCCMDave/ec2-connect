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
- **Credentials:** Supports both `.ps1` and `.txt` format
- **AWS CLI Check:** Prompts to install via winget if missing
- **Exit Timer:** 3-second countdown before exit (Option 0)

### Setup

1. Copy your `.pem` key file to `~/.ssh/`
2. Create `credentials.ps1` OR `credentials.txt` (see below)
3. Edit instance configuration in `connect-ec2.ps1`

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

**Option A: credentials.ps1**
```powershell
$env:AWS_ACCESS_KEY_ID = "ASIA..."
$env:AWS_SECRET_ACCESS_KEY = "..."
$env:AWS_SESSION_TOKEN = "..."
```

**Option B: credentials.txt**
```
AWS_ACCESS_KEY_ID=ASIA...
AWS_SECRET_ACCESS_KEY=...
AWS_SESSION_TOKEN=...
```

Both formats work. The `.txt` format is simpler to copy-paste from AWS Console.

**Security Note:** Both formats are equally secure when the file is in `.gitignore`. The credentials are only loaded into the current process environment.

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
- **Credentials:** Unterstützt `.ps1` und `.txt` Format
- **AWS CLI Check:** Bietet winget Installation an falls fehlend
- **Exit Timer:** 3-Sekunden Countdown beim Beenden (Option 0)

### Einrichtung

1. `.pem` Key-Datei nach `~/.ssh/` kopieren
2. `credentials.ps1` ODER `credentials.txt` erstellen (siehe unten)
3. Instanz-Konfiguration in `connect-ec2.ps1` anpassen

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

**Option A: credentials.ps1**
```powershell
$env:AWS_ACCESS_KEY_ID = "ASIA..."
$env:AWS_SECRET_ACCESS_KEY = "..."
$env:AWS_SESSION_TOKEN = "..."
```

**Option B: credentials.txt**
```
AWS_ACCESS_KEY_ID=ASIA...
AWS_SECRET_ACCESS_KEY=...
AWS_SESSION_TOKEN=...
```

Beide Formate funktionieren. Das `.txt` Format ist einfacher aus der AWS Console zu kopieren.

**Sicherheitshinweis:** Beide Formate sind gleich sicher, solange die Datei in `.gitignore` steht. Die Credentials werden nur in die aktuelle Prozess-Umgebung geladen.

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

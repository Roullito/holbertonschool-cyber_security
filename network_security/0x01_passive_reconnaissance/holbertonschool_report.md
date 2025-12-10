# Passive Reconnaissance Report – holbertonschool.com

## 1. Scope & Methodology

This report presents **passive reconnaissance** performed on the domain `holbertonschool.com` and its visible subdomains, using only **OSINT and non-intrusive techniques**:

- WHOIS lookup (`whois`)
- DNS enumeration (`nslookup`, `dig`, `subfinder`)
- Public exposure analysis (`Shodan`)
- Technology fingerprinting (headers, stack from Shodan / hosting)

No active exploitation, brute-force, or intrusive scanning (e.g. nmap, fuzzing) was performed.  
All observations are **informational only** and do not confirm actual exploitability.


## 1. WHOIS Summary

WHOIS data for `holbertonschool.com` reveals:

- **Organization:** Holberton Inc
- **Location:** 5670 Wilshire Blvd Suite 1802, Los Angeles, CA 90036, US
- **Contacts:** Registrant, Admin, and Tech contacts are all Holberton Inc; emails are obfuscated via Gandi (registrar).
- **Conclusion:** Holberton Inc is the legal owner and administrator of the domain.

---

## 2. DNS Analysis

### A Records (IPv4)

`holbertonschool.com` resolves to:

- `99.83.190.102`
- `75.2.70.75`

These IPs are part of AWS/Webflow infrastructure.

### MX Records (Email)

Email is handled by Google Workspace:

- `aspmx.l.google.com`
- `alt1.aspmx.l.google.com`
- `alt2.aspmx.l.google.com`
- `alt3.aspmx.l.google.com`
- `alt4.aspmx.l.google.com`

### TXT Records (Services & SPF)

- **SPF:** `v=spf1 include:mailgun.org include:_spf.google.com -all`
    - Outgoing email via Mailgun and Google.
- **Other Services:** Brevo, Stripe, Zapier, Loader.io, Intacct, Google/Microsoft site verifications.

### NS Records (Nameservers)

DNS is managed via AWS Route 53 (`awsdns-*`).

---

## 3. Subdomain Discovery

Subdomains were enumerated and deduplicated using:

```sh
cut -d',' -f1,2 holbertonschool.com.txt | sort -t',' -k1,1 -u > holbertonschool_clean.txt
```

### Unique Subdomain-IP Pairs

| Subdomain                              | IP              |
|-----------------------------------------|-----------------|
| apply.holbertonschool.com              | 13.39.187.93    |
| blog.holbertonschool.com               | 192.0.78.230    |
| en.fr.holbertonschool.com              | 104.17.201.193  |
| fr.holbertonschool.com                 | 15.160.106.203  |
| fr.webflow.holbertonschool.com         | 104.17.201.193  |
| help.holbertonschool.com               | 99.83.190.102   |
| holbertonschool.com                    | 75.2.70.75      |
| lvl2-discourse-staging.holbertonschool.com | 13.38.216.13 |
| rails-assets.holbertonschool.com       | 13.33.235.73    |
| read.holbertonschool.com               | 15.236.170.88   |
| smile2021.holbertonschool.com          | 15.161.34.42    |
| staging-apply-forum.holbertonschool.com| 13.38.122.220   |
| staging-apply.holbertonschool.com      | 15.236.53.167   |
| staging-rails-assets-apply.holbertonschool.com | 3.164.68.105 |
| support.holbertonschool.com            | 216.198.54.2    |
| v1.holbertonschool.com                 | 54.86.136.129   |
| v2.holbertonschool.com                 | 34.203.198.145  |
| v3.holbertonschool.com                 | 54.89.246.137   |
| webflow.holbertonschool.com            | 15.160.106.203  |
| www.holbertonschool.com                | 15.161.34.42    |
| yriry2.holbertonschool.com             | 52.47.143.83    |

**Categories:**
- **Production-facing:** holbertonschool.com, www, apply, read, help, fr, webflow, etc.
- **Staging/Internal:** staging-apply, staging-apply-forum, staging-rails-assets-apply, lvl2-discourse-staging.
- **Legacy/Campaign:** smile2021.holbertonschool.com.
- **Asset/CDN:** rails-assets, webflow, fr.webflow.

---

## 4. Shodan Findings – Key Hosts

### 4.1 holbertonschool.com (Redirector)

- **IP:** 35.180.27.154 (AWS, Paris)
- **Ports:** 80/tcp
- **Server:** nginx/1.18.0 (Ubuntu)
- **Behavior:** HTTP 301 redirect to main domain.

### 4.2 apply.holbertonschool.com (Admission Portal)

- **IP:** 13.39.187.93 (AWS EC2)
- **Ports:** 80/tcp, 443/tcp
- **Server:** nginx/1.20.0
- **Security:** Strong HTTP headers, HTTPS enforced, valid Amazon RSA certificate.
- **Framework:** Ruby on Rails.

### 4.3 yriry2.holbertonschool.com (Level2 Forum)

- **IP:** 52.47.143.83 (AWS EC2)
- **Ports:** 80/tcp, 443/tcp
- **Server:** nginx/1.21.6
- **Security:** HSTS, strict CSP, Discourse forum.
- **Certificate:** Let’s Encrypt ECDSA.

### 4.4 staging-apply.holbertonschool.com (Staging)

- **IP:** 15.236.53.167 (AWS EC2)
- **Ports:** 80/tcp, 443/tcp
- **Server:** nginx/1.20.0
- **Security:** HTTP Basic Auth over HTTPS.

### 4.5 blog.holbertonschool.com (WordPress.com)

- **IP:** 192.0.78.230 (Automattic)
- **Server:** nginx, WordPress.com infrastructure.
- **Certificate:** Let’s Encrypt, multi-tenant.

### 4.6 rails-assets.holbertonschool.com (CloudFront CDN)

- **IP:** 13.33.235.73 (Amazon CloudFront)
- **Role:** CDN endpoint for static assets.

### 4.7 fr.webflow.holbertonschool.com (Cloudflare)

- **IP:** 104.17.201.193 (Cloudflare)
- **Role:** Shared Cloudflare edge for Webflow.

### 4.8 smile2021.holbertonschool.com (Legacy/Campaign)

- **IP:** 15.161.34.42 (AWS EC2, Italy)
- **Ports:** 80/tcp, 81/tcp, 443/tcp
- **Role:** Legacy/campaign site.

---

## 5. Technology Stack Overview

- **CDN/Delivery:** AWS CloudFront, jsDelivr, Cloudflare
- **Web Servers:** nginx (1.18.0, 1.20.0, 1.21.6)
- **Frameworks:** Ruby on Rails, Discourse, WordPress.com, Webflow
- **Front-end:** jQuery, Slick, Adobe Fonts
- **Marketing/Automation:** Klaviyo, Brevo, Zapier
- **Analytics:** Google Tag Manager, Google Analytics

---

## 6. Vulnerability Considerations (Shodan)

Shodan flags several CVEs for detected software versions:

- **CVE-2025-23419:** TLS session ticket bypass
- **CVE-2023-44487:** HTTP/2 Rapid Reset DoS
- **CVE-2021-23017:** DNS resolver bug
- **CVE-2021-3618:** ALPACA cross-protocol attack

> **Note:** These are based on detected versions; not confirmed on Holberton infrastructure.

**Recommendations:**
- Keep nginx updated.
- Review HTTP/2 configuration.
- Harden DNS and TLS settings.
- Maintain access controls on staging environments.

---

## 7. Observations & Conclusion

**Attack Surface:**
- Public web front-ends (Rails, forum, marketing)
- Managed platforms (WordPress.com, Webflow, Cloudflare)
- Staging environments with HTTPS & Basic Auth

**Good Practices:**
- HTTPS enforced, HSTS enabled
- Strong security headers
- Separation of production/staging

**Points to Monitor:**
- nginx version updates
- Legacy/campaign subdomain exposure
- Subdomain inventory and decommissioning
- SaaS integrations and key management


#!/bin/bash
nmap --script http-vuln-cve2006-3392 $1 -oN vuln_scan_results.txt
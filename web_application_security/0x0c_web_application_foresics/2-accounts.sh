#!/bin/bash
tail -n 1000 auth.log | grep -v 'CRON' | grep 'USER=' | awk -F 'USER=' '{print $2}' | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 1 | awk '{print $2}'
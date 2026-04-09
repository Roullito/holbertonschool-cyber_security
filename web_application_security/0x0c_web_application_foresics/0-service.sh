#!/bin/bash
grep -wv -e cron -e login -e chauthtok -e su -e groupadd -e useradd -e chage -e chsh -e chfn auth.log | awk '{print $6}' | sort | uniq -c |sort -nr
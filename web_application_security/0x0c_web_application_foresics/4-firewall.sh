#!/bin/bash
grep -E 'iptables.*INPUT' auth.log | wc -l
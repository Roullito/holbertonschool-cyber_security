#!/bin/bash
hashcat --stdout -a 1 "$1" "$2" 2>/dev/null

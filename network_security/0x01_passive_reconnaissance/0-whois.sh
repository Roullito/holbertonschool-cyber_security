#!/bin/bash
whois $1 | awk -F': ' '/^(Registrant|Admin|Tech) /{f=$1;v=$2;if(f~/Ext$/)f=f":";if(f~/Street$/)v=v" ";print f","v}' > $1.csv

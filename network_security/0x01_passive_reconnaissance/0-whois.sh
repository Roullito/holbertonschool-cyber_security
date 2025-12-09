#!/bin/bash
whois $1 | awk -F': ' '/^(Registrant|Admin|Tech) (Name|Organization|Street|City|State\/Province|Postal Code|Country|Phone|Fax|Email|Phone Ext|Fax Ext):/ {f=$1;v=$2;if(f~/Ext$/)f=f":";if(f~/Street$/)v=v" ";print f","v}' > $1.csv

#!/bin/bash
whois $1|awk -F': ' '/^Registrant |^Admin |^Tech /{gsub(/^Registry /,"");if($1~/Street$/)$2=$2" ";print $1","$2}'>$1.csv

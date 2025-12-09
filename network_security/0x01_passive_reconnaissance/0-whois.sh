#!/bin/bash
whois $1|awk -F': ' '/^Registrant |^Admin |^Tech /{gsub(/^Registry /,"");print $1","$2}'>$1.csv
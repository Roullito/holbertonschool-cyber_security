#!/bin/bash
sudo nmap -sA -p $2 $1 --reason --host-timeout 1000ms

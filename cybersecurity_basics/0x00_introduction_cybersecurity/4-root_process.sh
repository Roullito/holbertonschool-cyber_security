#!/bin/bash
ps -u "$1" u --no-headers | grep -v ' 0 *0 '
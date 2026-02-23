#!/bin/bash
find $1 \(-type f -perm /2000 -o -perm /4000 \) -mtime -1 exec ls -l {} \; 2> /dev/null

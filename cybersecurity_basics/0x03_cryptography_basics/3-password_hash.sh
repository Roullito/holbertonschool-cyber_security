#!/bin/bash
echo -n "$1" + openssl rand -hex 16 | sha256sum | awk '{print $1}' > 3_hash.txt

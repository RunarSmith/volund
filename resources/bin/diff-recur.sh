#!/bin/bash


alt="$1"

for d in $( ls -d covea.* ); do
    echo -e "\n=== $d ===================="
    diff -r -x '.git' "$d" "${alt}/${d}"
done

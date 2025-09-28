#!/bin/bash


branch="$1"

for d in $( ls -d covea.* ); do
    echo -e "\n=== $d ===================="
    pushd $d
        if [ -d '.git' ]; then
            git checkout "${branch}"
        fi
    popd
done

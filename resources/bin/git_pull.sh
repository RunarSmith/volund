#!/bin/bash


for repo in $( ls -d *); do
    if [ -d $repo/.git ]; then
        echo "---------------------------------------------"
        pushd "$repo" > /dev/null
            echo "Repo: $(basename `pwd`) ($(git rev-parse --abbrev-ref HEAD))"
            git pull  
        popd > /dev/null
    fi
done

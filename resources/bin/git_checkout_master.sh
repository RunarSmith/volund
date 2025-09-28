#!/bin/bash

for repo in $(ls -d covea.*); do
    pushd $repo
        git checkout master
        git pull
    popd
done

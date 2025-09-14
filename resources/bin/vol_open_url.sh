#!/bin/bash

echo "$1" > $(mktemp -u /workspace/.to_host/open_url-XXXXXX.txt)

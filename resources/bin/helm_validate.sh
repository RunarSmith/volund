#!/bin/bash

# helm charts validation

# Note: This script assumes that Helm and the necessary plugins (like helm-unittest) are installed.

#set -e
#set -x

# source folder containing "Chart.yaml" file
ChartPath="$1"
# 
subPath="$2"

tmpPath=$(mktemp --directory "/tmp/lint-XXXXXX")
srcPath="$tmpPath/sources/"

#if [ -z "$yamlResult" ]; then
yamlResult="$(pwd)/helm-output.yaml"
#fi
trivyReport="$(pwd)/trivy-report.md"

mkdir -p $srcPath/
cp -r $ChartPath/* $srcPath/

on_exit(){
  rm -fr $tmpPath
}

trap 'on_exit' EXIT

if [ -z "$ChartPath" ]; then
  echo "Usage: $0 <path_to_helm_chart>"
  exit 1
fi

if [ ! -d "$ChartPath" ]; then
  echo "Error: Directory $ChartPath does not exist."
  exit 1
fi


echo "Result file will be: $yamlResult"

pushd $srcPath > /dev/null

echo "=== Update helm dependencies ==============================="
echo "Updating Helm chart dependencies..."
set -x
  helm dependency update .
set +x
if [ $? -ne 0 ]; then
  echo "Helm chart dependency update failed."
  exit 1
fi

echo "Helm chart dependencies updated successfully."

echo "=== Validating Helm chart in $ChartPath ===================="
if [ -f ./values.yaml ]; then
  echo "=>> Using 'values.yaml' for validation."

  if [ ! -z $subPath ]; then
    set -x
      helm lint --strict . --values values.yaml --values $subPath/values-static.yaml
    set +x
  else
    set -x
      helm lint --strict . --values values.yaml
    set +x
  fi
else
  set -x
    helm lint --strict .
  set +x
fi
if [ $? -ne 0 ]; then
  echo "Helm chart validation failed."
  exit 1
fi

echo "Helm chart validation successful."

echo "=== Resolve Helm chart templating =========================="
echo "Resolving Helm chart tempalting..."
if [ -f values.yaml ]; then
  echo "=>> Using 'values.yaml' for templating."

  if [ ! -z $subPath ]; then
    set -x
      helm template . --values values.yaml --values $subPath/values-static.yaml > $yamlResult
    set +x
  else
    set -x
      helm template . --values values.yaml > $yamlResult
    set +x
  fi
else
  helm template . > $yamlResult
fi
if [ $? -ne 0 ]; then
  echo "Helm chart templating failed."
  exit 1
fi

echo "Helm chart templating successful."

echo "=== Validate the rendered YAML ============================="
echo "Validating rendered YAML..."
# https://yamllint.readthedocs.io/en/stable/rules.html
cat <<EOF > .yamllint
extends: default
rules:
rules:
  braces:
    level: warning
  colons:
    level: warning
    max-spaces-before: 0
    max-spaces-after: 1
  comments:
    level: warning
    require-starting-space: true
  empty-lines:
    level: warning
    max: 0
    max-start: 0
    max-end: 0
  indentation:
    level: error
    spaces: 2
    indent-sequences: whatever
  new-lines:
    level: warning
    type: platform
  trailing-spaces:
    level: warning
  # 120 chars should be enough, but don't fail if a line is longer
  line-length:
    max: 120
    level: warning
EOF

set -x
  yamllint $yamlResult
set +x
if [ $? -ne 0 ]; then 
  echo "YAML validation failed."
  exit 1
fi

echo "YAML validation successful."

echo "=== Execute helm unit tests ================================"
if [ -d "./tests" ]; then
  echo "Executing Helm tests..."
  set -x
    helm unittest "."
  set +x
  if [ $? -ne 0 ]; then
    echo "Helm tests failed."
    exit 1
  fi
else
  echo "No Helm tests found in $ChartPath/tests."
fi

echo "Helm tests executed successfully."

echo "=== Execute trivy / SAST ==================================="
set -x
  trivy config --output $trivyReport $yamlResult
set +x

# Clean up
echo "All validations completed successfully."

# --- End of script ----------------------------------------

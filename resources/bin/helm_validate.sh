#!/bin/bash

# helm charts validation

# Note: This script assumes that Helm and the necessary plugins (like helm-unittest) are installed.

#set -e
#set -x

# source folder containing "Chart.yaml" file
ChartPath="$1"
# 
yamlResult="$2"

tmpPath=$(mktemp --directory "/tmp/lint-XXXXXX")
srcPath="$tmpPath/sources/"
venvPath="$tmpPath/venv"

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

if [ -z "$yamlResult" ]; then
  yamlResult="$(pwd)/helm_template_output.yaml"
fi

echo "Result file will be: $yamlResult"

echo "=== Installing venv ========================================"
python3 -m venv $venvPath 

source $venvPath/bin/activate 

echo "=== Installing tools ======================================="
pip install --no-cache-dir --upgrade pip

pip install yamllint

pushd $srcPath > /dev/null

echo "=== Update helm dependencies ==============================="
echo "Updating Helm chart dependencies..."
helm dependency update .
if [ $? -ne 0 ]; then
  echo "Helm chart dependency update failed."
  exit 1
fi

echo "Helm chart dependencies updated successfully."

echo "=== Validating Helm chart in $ChartPath ===================="
if [ -f ./values.yaml ]; then
  echo "=>> Using 'values.yaml' for validation."
  helm lint --strict . --values values.yaml
else
  helm lint --strict .
fi
if [ $? -ne 0 ]; then
  echo "Helm chart validation failed."
  exit 1
fi

echo "Helm chart validation successful."

echo "=== Resolve Helm chart templating =========================="
echo "Resolving Helm chart tempalting..."
if [ ! -d "./templates" ]; then
  echo "Error: No templates directory found in $ChartPath."
  exit 1
fi
if [ -f values.yaml ]; then
  echo "=>> Using 'values.yaml' for templating."
  helm template . --values values.yaml > $yamlResult
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
cat <<EOF > .yamllint
extends: default
rules:
rules:
  braces:
    level: warning
  indentation:
    level: warning

  # 120 chars should be enough, but don't fail if a line is longer
  line-length:
    max: 120
    level: warning
EOF
yamllint $yamlResult
if [ $? -ne 0 ]; then 
  echo "YAML validation failed."
  exit 1
fi

echo "YAML validation successful."

echo "=== Execute helm unit tests ================================"
if [ -d "./tests" ]; then
  echo "Executing Helm tests..."
  helm unittest "."
  if [ $? -ne 0 ]; then
    echo "Helm tests failed."
    exit 1
  fi
else
  echo "No Helm tests found in $ChartPath/tests."
fi

echo "Helm tests executed successfully."

# Clean up
echo "All validations completed successfully."

# --- End of script ----------------------------------------

deactivate

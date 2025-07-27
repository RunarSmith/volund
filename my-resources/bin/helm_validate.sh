#!/bin/bash

# helm charts validation

# Note: This script assumes that Helm and the necessary plugins (like helm-unittest) are installed.

set -e

ChartPath="$1"
if [ -z "$ChartPath" ]; then
  echo "Usage: $0 <path_to_helm_chart>"
  exit 1
fi

if [ ! -d "$ChartPath" ]; then
  echo "Error: Directory $ChartPath does not exist."
  exit 1
fi


if [ ! -d /opt/ansible-venv ]; then
    python3 -m venv /opt/ansible-venv 
fi

source /opt/ansible-venv/bin/activate 

if [ ! -f /opt/ansible-venv/bin/yamllint ]; then
    pip install --no-cache-dir --upgrade pip

    pip install ansible ansible-lint yamllint
fi

# --- Validate the Helm chart -----------------------------
echo "Validating Helm chart in $ChartPath..."
helm lint "$ChartPath"
if [ $? -ne 0 ]; then
  echo "Helm chart validation failed."
  exit 1
fi

echo "Helm chart validation successful."

# --- Update helm dependencies ----------------------------
echo "Updating Helm chart dependencies..."
helm dependency update "$ChartPath"
if [ $? -ne 0 ]; then
  echo "Helm chart dependency update failed."
  exit 1
fi

echo "Helm chart dependencies updated successfully."

# --- Resolve Helm chart templating -----------------------
echo "Resolving Helm chart tempalting..."
helm template "$ChartPath" > /tmp/helm_template_output.yaml
if [ $? -ne 0 ]; then
  echo "Helm chart templating failed."
  exit 1
fi

echo "Helm chart templating successful."

# --- Validate the rendered YAML ---------------------------
echo "Validating rendered YAML..."
yamllint /tmp/helm_template_output.yaml
if [ $? -ne 0 ]; then 
  echo "YAML validation failed."
  exit 1
fi

echo "YAML validation successful."

# --- Execute helm unit tests -----------------------------
if [ -d "$ChartPath/tests" ]; then
  echo "Executing Helm tests..."
  helm unittest "$ChartPath"
  if [ $? -ne 0 ]; then
    echo "Helm tests failed."
    exit 1
  fi
else
  echo "No Helm tests found in $ChartPath/tests."
fi

echo "Helm tests executed successfully."

# Clean up
rm -f /tmp/helm_template_output.yaml
echo "All validations completed successfully."

# --- End of script ----------------------------------------

deactivate

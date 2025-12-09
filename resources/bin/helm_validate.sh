#!/bin/bash

# helm charts validation

# Note: This script assumes that Helm and the necessary plugins (like helm-unittest) are installed.

#set -e
#set -x

usage() {
    echo "**Usage:** $0 [-a][-h][-t][-u] -p <path> [-s <sub-path>]

helm templating and validation

* -a :            execute all
* -f :            specify a values.yaml file to use
* -h :            show this helm message
* -p \<path\>:      path to the root folder that contain the 'Chart.yaml' and 'values.yaml' files
* -s \<sub-path\> : sub path in the component that contain a 'values-static.yaml' file
* -t :            execute trivy chec
* -u :            execute unit tests

" | glow -w0 1>&2;
    exit 1;
}

useTrivy=0
execUnitTests=0
valuesFile=""

while getopts "af:htup:s:" option; do
    case "${option}" in
        a)
            useTrivy=1
            execUnitTests=1
            ;;
        f)
            valuesFile="$OPTARG"
            ;;
        h)
            usage
            ;;
        p)
            ChartPath="$OPTARG"
            ;;
        s)
            subPath="$2"
            ;;
        t)
            useTrivy=1
            ;;
        u)
            execUnitTests=1
            ;;
        *)
            usage
            ;;
    esac
done


. /opt/resources/lib/term.sh

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
  _ERROR "Usage: $0 <path_to_helm_chart>"
  exit 1
fi

if [ ! -d "$ChartPath" ]; then
  _ERROR "Error: Directory $ChartPath does not exist."
  exit 1
fi

if [ ! -z "$valuesFile" ]; then
  if [ ! -f "$valuesFile" ]; then
    _ERROR "Error: Faile $valuesFile does not exist."
    exit 1
  fi
fi

echo "Result file will be: $yamlResult"

pushd $srcPath > /dev/null

_INFO "Update helm dependencies"
echo "Updating Helm chart dependencies..."
set -x
  helm dependency update .
set +x
if [ $? -ne 0 ]; then
  _ERROR "Helm chart dependency update failed."
  exit 1
fi

_SUCCESS "Helm chart dependencies updated successfully."


if [ ! -z "$valuesFile" ]; then
  customValueFile="--values $valuesFile"
fi

if [ ! -z $subPath ]; then
  subPathValueFile="--values $subPath/values-static.yaml"
fi

allValuesFiles="--values values.yaml $subPathValueFile $customValueFile"

_INFO "Validating Helm chart in $ChartPath"
if [ -f ./values.yaml ]; then
  echo "=>> Using 'values.yaml' for validation."

  set -x
    helm lint --strict . $allValuesFiles
  set +x
else
  set -x
    helm lint --strict .
  set +x
fi
if [ $? -ne 0 ]; then
  _ERROR "Helm chart validation failed."
  exit 1
fi

_SUCCESS "Helm chart validation successful."



_INFO "Resolve Helm chart templating"
echo "Resolving Helm chart tempalting..."
if [ -f values.yaml ]; then
  echo "=>> Using 'values.yaml' for templating."

  set -x
    helm template . $allValuesFiles > $yamlResult
  set +x

else
  helm template . > $yamlResult
fi
if [ $? -ne 0 ]; then
  _ERROR "Helm chart templating failed."
  exit 1
fi

_SUCCESS "Helm chart templating successful."



_INFO "Validate the rendered YAML"
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
  _ERROR "YAML validation failed."
  exit 1
fi

_SUCCESS "YAML validation successful."


if [[ $execUnitTests -eq 1 ]]; then
  _INFO "Execute helm unit tests"
  if [ -d "./tests" ]; then
    echo "Executing Helm tests..."
    set -x
      helm unittest "."
    set +x
    if [ $? -ne 0 ]; then
      _ERROR "Helm tests failed."
      exit 1
    fi
  else
    _WARN "No Helm tests found in $ChartPath/tests."
  fi

  _SUCCESS "Helm tests executed successfully."
fi

if [[ $useTrivy -eq 1 ]]; then
  _INFO "=== Execute trivy / SAST ==================================="
  set -x
    trivy config --output $trivyReport $yamlResult
  set +x

fi

# Clean up
_SUCCESS "All validations completed successfully."

# --- End of script ----------------------------------------

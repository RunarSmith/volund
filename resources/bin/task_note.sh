#!/bin/bash

notesFolder=/workspace/notes

[ ! -d ${notesFolder} ] && mkdir ${notesFolder}

# ============================================================
function open_note_file() {
    local taskFile=$1
    vol_open_code.sh "/notes/${taskFile}"
}

# ============================================================
function create_note_from_task() {

    local taskId=$1
    local taskFile=$2

    local taskTags=$(task _get $taskId.tags)
    local taskProject=$(task _get $taskId.project)
    local taskDescription=$(task _get $taskId.description)

    # Start front matter
    cat <<EOF > "${notesFolder}/${taskFile}"
---
taskUuid: ${taskUuid}
project: ${taskProject}
tags:
EOF

    # add tags
    IFS=',' read -ra tag_array <<< "$taskTags"
    for tag in "${tag_array[@]}"; do
        echo "  - $tag" >> "${notesFolder}/${taskFile}"
    done

    # End of frontmatter, start text
    cat <<EOF >> "${notesFolder}/${taskFile}"
---

# ${taskDescription}
EOF
}

# ============================================================

function open_note() {

    local taskId=$1
    
    local taskUuid=$(task _get $taskId.uuid)
    
    pushd ${notesFolder} > /dev/null
    fileExists=$( grep --files-with-matches -r -E "^taskUuid: ${taskUuid}\$" * )
    popd > /dev/null

    if [ -z ${fileExists} ]; then
        echo "Create note file"

        local taskDescription=$(task _get $taskId.description)

        local taskFile="$( echo "${taskDescription}" | iconv -f utf8 -t ascii//TRANSLIT \
        | tr '[:upper:]' '[:lower:]' \
        | sed -E 's/[^a-z0-9]+/-/g' \
        | sed -E 's/-+/-/g' \
        | sed -E 's/^-|-$//g' ).md"

        echo "task ${taskId} > ${taskUuid} > ${taskFile}"

        create_note_from_task ${taskId} ${taskFile} 

        open_note_file ${taskFile} 

    else
        echo "Found note file: ${fileExists}"
        open_note_file ${fileExists}
    fi

    
}

# ============================================================

taskId="$1"

case ${taskId} in
    "ls")
      pushd ${notesFolder} > /dev/null
      find . -type f -name "*.md"
      popd > /dev/null
    ;;
    *)
      open_note ${taskId} ${taskFile}
    ;;
esac


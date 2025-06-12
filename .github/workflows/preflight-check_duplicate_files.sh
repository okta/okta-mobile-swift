#!/bin/bash
set -uo pipefail

if [[ "$#" -lt 1 || -z "$1" ]]; then
    echo "ERROR: Supply a path to the directory to check"
    exit 1
fi

SOURCE_DIR=$1
DUPLICATE_BASENAMES_FILE=$(mktemp)
TEMP_FINAL_ALL_DUPLICATE_PATHS=$(mktemp)

trap 'rm -f "$DUPLICATE_BASENAMES_FILE" "$TEMP_FINAL_ALL_DUPLICATE_PATHS"' EXIT

HAS_DUPLICATES_RESULT="false"
DUPLICATE_PATHS_LIST_RESULT="" # Will be a multi-line string

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "INFO: Directory '$SOURCE_DIR' not found. Skipping duplicate filename check."
    {
      echo "has_duplicates=false"
      echo "duplicate_paths_list="
    } >> "$GITHUB_OUTPUT"
    exit 0
fi

echo "Scanning '$SOURCE_DIR' for duplicate filenames..." >> $GITHUB_STEP_SUMMARY
find "$SOURCE_DIR" -type f -name '*.swift' -exec basename '{}' ';' | sort | uniq -d > "$DUPLICATE_BASENAMES_FILE"

if [[ -s "$DUPLICATE_BASENAMES_FILE" ]]; then
    HAS_DUPLICATES_RESULT="true"
    echo "" >> $GITHUB_STEP_SUMMARY
    echo "ERROR: Duplicate filenames detected"
    echo "| Filename | Conflicting File Paths |" >> $GITHUB_STEP_SUMMARY
    echo "| --- | --- |" >> $GITHUB_STEP_SUMMARY

    while IFS= read -r dup_basename; do
        if [[ -z "$dup_basename" ]]; then
            continue
        fi

        paths_for_this_basename_array=()

        while IFS= read -r -d $'\0' found_path; do
            paths_for_this_basename_array+=("$found_path")
            echo "$found_path" >> "$TEMP_FINAL_ALL_DUPLICATE_PATHS"
            echo "::error file=$found_path,title=Duplicate file detected::Filename $dup_basename conflicts with other files with the same name"
        done < <(find "$SOURCE_DIR" -type f -name "$dup_basename" -print0)

        path_list_for_table_cell=""
        if [[ ${#paths_for_this_basename_array[@]} -gt 0 ]]; then
            path_list_for_table_cell=$(printf "%s, " "${paths_for_this_basename_array[@]}")
            path_list_for_table_cell=${path_list_for_table_cell%, }
        fi

        echo "| ${dup_basename} | ${path_list_for_table_cell} |" >> $GITHUB_STEP_SUMMARY
    done < "$DUPLICATE_BASENAMES_FILE"

    if [[ -s "$TEMP_FINAL_ALL_DUPLICATE_PATHS" ]]; then
        DUPLICATE_PATHS_LIST_RESULT=$(sort -u "$TEMP_FINAL_ALL_DUPLICATE_PATHS" | sed '/^$/d')
    fi

    {
        echo "has_duplicates=true"
        echo "duplicate_paths_list<<DUPLICATE_PATHS_EOF"
        echo "$DUPLICATE_PATHS_LIST_RESULT"
        echo "DUPLICATE_PATHS_EOF"
    } >> "$GITHUB_OUTPUT"
    exit 1
else
    {
      echo "has_duplicates=false"
      echo "duplicate_paths_list="
    } >> "$GITHUB_OUTPUT"
fi
exit 0

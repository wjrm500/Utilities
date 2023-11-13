#!/bin/bash

# Function to print usage
usage() {
    echo "Usage: $0 --combine-at [path_to_directory] [--include ext1,ext2,...] [--exclude ext1,ext2,...] [--output-to path_to_output_file]"
    exit 1
}

# Default values for include, exclude, and output file
include=()
exclude=()
output_file=""

# Parse the command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --combine-at) directory="$2"; shift ;;
        --include) IFS=',' read -r -a include <<< "$2"; shift ;;
        --exclude) IFS=',' read -r -a exclude <<< "$2"; shift ;;
        --output-to) output_file="$2"; shift ;;
        *) usage ;;
    esac
    shift
done

# Check if directory is provided
if [ -z "$directory" ]; then
    usage
fi

# Check if the provided directory exists
if [ ! -d "$directory" ]; then
    echo "Directory does not exist."
    exit 1
fi

# Set default output file name if not specified
if [ -z "$output_file" ]; then
    output_file="output_$(date +%Y%m%d%H%M%S).txt"
fi

# Function to check if the file extension is in the include list
is_included() {
    local ext=$1
    [[ ${#include[@]} -eq 0 ]] && return 0
    for i in "${include[@]}"; do
        [[ "$i" == "$ext" ]] && return 0
    done
    return 1
}

# Function to check if the file extension is in the exclude list
is_excluded() {
    local ext=$1
    for e in "${exclude[@]}"; do
        [[ "$e" == "$ext" ]] && return 0
    done
    return 1
}

# Iterate over all files in the given directory and its subdirectories
find "$directory" -type f | while read file; do
    ext="${file##*.}"
    if is_included "$ext" && ! is_excluded "$ext"; then
        echo -e "// $file" >> "$output_file"
        cat "$file" >> "$output_file"
        echo -e "\n\n" >> "$output_file"
    fi
done

# Print the full path of the output file
absolute_output_path=$(realpath "$output_file")
echo "File saved at $absolute_output_path"
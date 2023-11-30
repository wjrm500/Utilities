#!/bin/bash

# Function to print usage
usage() {
    echo "Usage: $0 --combine-at [path_to_directory] [--include-pattern pattern1,pattern2,...] [--exclude-pattern pattern1,pattern2,...] [--include-at dir1,dir2,...] [--exclude-at dir1,dir2,...] [--output-to path_to_output_file]"
    exit 1
}

# Default values for include and exclude patterns and directories
include_patterns=()
exclude_patterns=()
include_dirs=()
exclude_dirs=()
output_file=""
verbose=0

# Parse the command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --combine-at) directory="$2"; shift ;;
        --include-pattern) IFS=',' read -r -a include_patterns <<< "$2"; shift ;;
        --exclude-pattern) IFS=',' read -r -a exclude_patterns <<< "$2"; shift ;;
        --include-at) IFS=',' read -r -a include_dirs <<< "$2"; shift ;;
        --exclude-at) IFS=',' read -r -a exclude_dirs <<< "$2"; shift ;;
        --output-to) output_file="$2"; shift ;;
        --verbose) verbose=1 ;;
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

# Clear the output file before starting to append data
> "$output_file"

# Function to check if the file matches the include pattern
is_included_pattern() {
    local filename=$(basename "$1")
    [[ ${#include_patterns[@]} -eq 0 ]] && return 0
    for pattern in "${include_patterns[@]}"; do
        if [[ "$filename" == $pattern ]]; then
            return 0
        fi
    done
    return 1
}

# Function to check if the file matches the exclude pattern
is_excluded_pattern() {
    local filename=$(basename "$1")
    for pattern in "${exclude_patterns[@]}"; do
        if [[ "$filename" == $pattern ]]; then
            return 0
        fi
    done
    return 1
}

# Function to get the relative path of the file from the base directory
get_relative_path() {
    local file_path=$1
    local base_path=$2
    echo "${file_path#$base_path/}"
}

# Function to check if the file's directory is in the include list
is_included_dir() {
    local file_path=$(get_relative_path "$1" "$directory")
    [[ ${#include_dirs[@]} -eq 0 ]] && return 0
    for i in "${include_dirs[@]}"; do
        if [[ "$file_path" == "$i"* ]]; then
            return 0
        fi
    done
    return 1
}

# Function to check if the file's directory is in the exclude list
is_excluded_dir() {
    local file_path=$(get_relative_path "$1" "$directory")
    for e in "${exclude_dirs[@]}"; do
        if [[ "$file_path" == "$e"* ]]; then
            return 0
        fi
    done
    return 1
}

# Function to optionally print a message in verbose mode
verbose_print() {
    if [ "$verbose" -eq 1 ]; then
        echo "$1"
    fi
}

# Iterate over all files in the given directory and its subdirectories
find "$directory" -type f | while read file; do
    if is_included_pattern "$file" && ! is_excluded_pattern "$file" && is_included_dir "$file" && ! is_excluded_dir "$file"; then
        verbose_print "Adding $file"
        echo -e "// $file" >> "$output_file"
        cat "$file" >> "$output_file"
        echo -e "\n\n" >> "$output_file"
    else
        verbose_print "Skipping $file"
    fi
done

# Print the full path of the output file
absolute_output_path=$(realpath "$output_file")
echo "File saved at $absolute_output_path"
#!/bin/bash
# Convert ImageContentSourcePolicy YAML to registries.conf TOML format
set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <icsp.yaml>" >&2
    exit 1
fi

icsp_file="$1"

if [ ! -f "$icsp_file" ]; then
    echo "Error: File not found: $icsp_file" >&2
    exit 1
fi

# Verify it's an ICSP resource
kind=$(yq eval '.kind' "$icsp_file")
if [ "$kind" != "ImageContentSourcePolicy" ]; then
    echo "Error: Not an ImageContentSourcePolicy (found: $kind)" >&2
    exit 1
fi

# Get number of mirror entries
count=$(yq eval '.spec.repositoryDigestMirrors | length' "$icsp_file")

# Generate TOML for each mirror entry
for ((i=0; i<count; i++)); do
    source=$(yq eval ".spec.repositoryDigestMirrors[$i].source" "$icsp_file")
    mirrors=$(yq eval ".spec.repositoryDigestMirrors[$i].mirrors[]" "$icsp_file")

    echo "[[registry]]"
    echo "  prefix = \"$source\""
    echo "  location = \"$source\""
    echo ""

    while IFS= read -r mirror; do
        [ -z "$mirror" ] && continue
        echo "  [[registry.mirror]]"
        echo "    location = \"$mirror\""
    done <<< "$mirrors"

    echo ""
done

#!/usr/bin/env bash
set -euo pipefail

diagram_dir="$(cd "$(dirname "$0")" && pwd)"

for name in classes domaine sequence cas_utilisation; do
  source_file="$diagram_dir/$name.mmd"

  npx --yes @mermaid-js/mermaid-cli \
    -i "$source_file" \
    -o "$diagram_dir/$name.png" \
    --scale 3

  npx --yes @mermaid-js/mermaid-cli \
    -i "$source_file" \
    -o "$diagram_dir/$name.svg"

  npx --yes @mermaid-js/mermaid-cli \
    -i "$source_file" \
    -o "$diagram_dir/$name.pdf"
done

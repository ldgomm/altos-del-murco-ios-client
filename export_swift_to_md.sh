#!/bin/bash

OUTPUT="project_swift_files.md"
ROOT_DIR="."

> "$OUTPUT"

find "$ROOT_DIR" -type f -name "*.swift" \
  ! -path "*/Pods/*" \
  ! -path "*/.build/*" \
  ! -path "*/build/*" \
  ! -path "*/DerivedData/*" \
  ! -path "*/.git/*" | sort | while read -r file; do
    rel_path="${file#./}"
    {
      echo "# $rel_path"
      echo
      echo '```swift'
      cat "$file"
      echo
      echo '```'
      echo
      echo "---"
      echo
    } >> "$OUTPUT"
done

echo "Created $OUTPUT"

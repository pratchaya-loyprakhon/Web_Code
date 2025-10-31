#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: ./count_uses.sh filename"
    exit 1
fi

input="$1"
output="output.txt"

cat "$input" | \
tr '[:upper:]' '[:lower:]' | \
sed 's/[^a-z]/ /g' | \
tr -s ' ' '\n' | \
grep -v '^$' | \
sort | \
uniq -c | \
sort -k1,1nr -k2,2 | \
awk '{print $2, $1}' > "$output"

echo "Result written to $output"

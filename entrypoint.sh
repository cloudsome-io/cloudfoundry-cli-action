#!/bin/sh -l

cf api "$INPUT_CF_API"
cf auth "$INPUT_USERNAME" "$INPUT_PASSWORD"

if [ -n "$INPUT_ORG" ] && [ -n "$INPUT_SPACE" ]; then
  cf target -o "$INPUT_ORG" -s "$INPUT_SPACE"
fi

sh -c "cf $*"
#!/bin/bash

for file in "$@"; do
  node "$file"
done

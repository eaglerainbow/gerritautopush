#!/bin/bash

echo "DEBUG: Git Mock was called with: $@"

if [[ "$@" =~ 'commit --message' ]]; then
	# negative test simulating some commit failure
	exit 1
fi 

git "$@"

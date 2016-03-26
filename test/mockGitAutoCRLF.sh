#!/bin/bash

echo "DEBUG: Git Mock was called with: $@"

if [[ "$@" =~ 'commit --message' ]]; then
	if [ "$MOCK_RESPONSE" == "" ]; then
		echo "INTERNAL ERROR: MOCK_RESPONSE is not specified!"
		exit 255
	fi
	echo "$@" > $MOCK_RESPONSE
fi 

git "$@"

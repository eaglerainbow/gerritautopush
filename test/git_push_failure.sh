#!/bin/bash

echo "dummy implementation of git tool was called with $*"

if [ "$1" == "push" ]; then
	echo "Push command detected; returning failure exit code 1"
	exit 1
fi 

git "${@}"

exit $?


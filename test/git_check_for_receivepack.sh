#!/bin/bash

echo "dummy implementation of git tool was called with $*"

if [ "$1" == "push" ]; then
	if [[ "${@}" != *"receive_pack_dummy"* ]]; then
		echo "Receive pack parameter was not part of the parameters to git"
		exit 1
	fi
fi 

git "${@}"

exit $?


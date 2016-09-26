#!/bin/bash

echo "dummy implementation of git tool was called with $*"

if [ "$1" == "push" ]; then
	echo "Push command detected; dump of parameters passed:"
	echo "1: $1"
	echo "2: $2"
	echo "3: $3"
	if [ "$2" != '--receive-pack="git receive-pack receive_pack dummy"' ]; then
		echo "Receive pack parameter was not part of the parameters to git"
		exit 1
	else
		# we need to remove the parameter from the call, as local receive-packing won't work as expected
		echo "running git command with $1 $3 instead"
		git "$1" "$3" 
		exit $?
	fi
fi 

git "${@}"

exit $?


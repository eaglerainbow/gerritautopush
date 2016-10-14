#!/bin/bash

echo "dummy implementation of git tool was called with $*"

if [ "$1" == "push" ]; then
	echo "Push command detected; further operators are"
	echo "2: $2"
	echo "3: $3"
	
	# idea see also http://stackoverflow.com/questions/229551/string-contains-in-bash
	if [[ $3 != *"cc=dummyuser@example.bogus,cc=dummyuser2@example.bogus"* ]]; then
		echo "CC user is missing in refspec extension"
		exit 1
	fi
	
	git push "$2" refs/heads/master
	exit $?
fi 

git "${@}"

exit $?


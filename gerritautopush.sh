#!/bin/bash


# on getopts parsing see also http://wiki.bash-hackers.org/howto/getopts_tutorial

while getopts ":u:e:" opt; do
	case $opt in
	u)
		USERNAME=$OPTARG
		;;
	e)
		EMAILADDRESS=$OPTARG
		;;
	\?)
		echo "Invalid option: -$OPTARG" >&2
		exit 1
		;;
	:)
		echo "Invalid parameters: Option -$OPTARG requires an argument" >&2
		exit 1
	esac
done

if [ ! -x .git ]; then
	echo "Local directory is not containing a git repository" >&2
	exit 1
fi

# Set user configuration parameters
if [ "$USERNAME" != "" ]; then
	git config --local --add user.name $USERNAME
fi

if [ "$EMAILADDRESS" != "" ]; then
	git config --local --add user.email $EMAILADDRESS
fi

exit 0

#!/bin/bash


# on getopts parsing see also http://wiki.bash-hackers.org/howto/getopts_tutorial

while getopts ":u:e:s" opt; do
	case $opt in
	u)
		# Setting username locally before doing any further action
		USERNAME=$OPTARG
		;;
	e)
		# Setting email address locally before doing any further action
		EMAILADDRESS=$OPTARG
		;;
	s)
		# stage all changes before doing further activities
		STAGE_ALL=true
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

# ********************* Main Routine *******************

# Do sanity check before we start
if [ ! -x .git ]; then
	echo "Local directory is not containing a git repository" >&2
	exit 1
fi

# Prepare environment

# Set user configuration parameters
if [ "$USERNAME" != "" ]; then
	echo "Setting local user name for commits to $USERNAME"
	git config --local --add user.name $USERNAME
fi

if [ "$EMAILADDRESS" != "" ]; then
	echo "Setting local email address for commits to $EMAILADDRESS"
	git config --local --add user.email $EMAILADDRESS
fi


# Stage all changes if requested
if [ "$STAGE_ALL" == "true" ]; then
	echo "Staging all changes..."
	git add --all || exit 1
fi

exit 0

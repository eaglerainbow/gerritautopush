#!/bin/bash


function printhelp {
cat <<EOT
usage: gerritautopush [options]

valid options:
  -u [username]     set the user name of commits to 'username' locally before processing
  -e [emailaddress] set the email address of commits to 'emailaddress' locally before processing
  -s                stage all changes in the working directory (if not set, 
                    staging is expected to have already been done externally)

Options may appear multiple times on the command line; if used redundantly, the last 
value provided is considered to be the valid one.
EOT
}


# on getopts parsing see also http://wiki.bash-hackers.org/howto/getopts_tutorial
while getopts ":hu:e:s" opt; do
	case $opt in
	u)
		# Setting username locally before doing any further action
		GIT_USERNAME=$OPTARG
		;;
	e)
		# Setting email address locally before doing any further action
		GIT_EMAILADDRESS=$OPTARG
		;;
	s)
		# stage all changes before doing further activities
		STAGE_ALL=true
		;;
	h)
		printhelp
		exit 0
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
if [ "$GIT_USERNAME" != "" ]; then
	echo "Setting local user name for commits to $GIT_USERNAME"
	git config --local --add user.name $GIT_USERNAME
fi

if [ "$GIT_EMAILADDRESS" != "" ]; then
	echo "Setting local email address for commits to $GIT_EMAILADDRESS"
	git config --local --add user.email $GIT_EMAILADDRESS
fi


# Stage all changes if requested
if [ "$STAGE_ALL" == "true" ]; then
	echo "Staging all changes..."
	git add --all || exit 1
fi

echo "Checking if there is something to commit"
git diff-index --quiet HEAD
COMMIT_CHECK=$?
if [ $COMMIT_CHECK == 0 ]; then
	echo "No changes to commit; nothing to do"
	exit 0
fi
echo "There are changes in the repository which will be commited:"
git status -s

exit 0

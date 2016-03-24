#!/bin/bash


function printhelp {
cat <<EOT
usage: gerritautopush [options]

valid options:
  -u [username]     set the user name of commits to 'username' locally before processing
  -e [emailaddress] set the email address of commits to 'emailaddress' locally before processing
  -s                stage all changes in the working directory (if not set, 
                    staging is expected to have already been done externally)
  -c                commit changes which are staged
  -m [text]         use the 'text' as message for the commit subject line 
                    (use quotes, if it contains spaces!)
  -n [value]        Set the CRLF handling mode (core.autocrlf) to 'value' for
                    when committing

Note: Providing a commit message is mandatory, if you have specified the -c option

Options may appear multiple times on the command line; if used redundantly, the last 
value provided is considered to be the valid one.
EOT
}


# on getopts parsing see also http://wiki.bash-hackers.org/howto/getopts_tutorial
while getopts ":hu:e:scm:n:" opt; do
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
	c)
		# commit changes
		COMMIT_CHANGES=true
		;;
	m)
		# command line commit message provided
		COMMIT_MESSAGE=$OPTARG
		;;
	n)
		case $OPTARG in
		true)
			;;
		false)
			;;
		auto)
			;;
		*)
			echo "Unknown value: setting autoCRLF to $OPTARG is not supported" >&2
			exit 1
		esac
		AUTOCRLF=$OPTARG
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

# Verify that the options provided are consistent
if [ "$COMMIT_CHANGES" == "true" ]; then
	# we shall commit - do we have some message as well?
	if [ "$COMMIT_MESSAGE" == "" ]; then
		echo "Commit requested, but no commit message provided"
		exit 1
	fi
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

if [ "$COMMIT_CHANGES" != "true" ]; then
	echo "Committing not requested; stop processing"
	exit 0
fi

GIT_OPTIONS=""

if [ "$AUTOCRLF" != "" ]; then
	GIT_OPTIONS+=" -c core.autocrlf=$AUTOCRLF"
fi

if [ "$COMMIT_MESSAGE" != "" ]; then
	git $GIT_OPTIONS commit "--message=$COMMIT_MESSAGE"
else
	echo "SHOULD NOT BE REACHED" >&2
	exit 255
fi

GIT_COMMIT_RET=$?
if [ "$GIT_COMMIT_RET" != 0 ]; then
	echo "ERROR: git commit stopped with error code $GIT_COMMIT_RET" >&2
	exit 1
fi

exit 0

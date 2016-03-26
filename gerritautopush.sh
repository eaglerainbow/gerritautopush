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
  -d                after committing, dump the contents of the commit which was created
  -f [hostname]     fetch the commit-msg file for generating gerrit-compatible
                    Change-IDs from 'hostname' (may optionally contain a port, which
                    needs to be separated by a colon, i.e. mygerritserver:8081)
                    By default, https is being used to approach the gerrit server.
                    Alternatively, you may also specify the protocol using the URL notation.
                    Example: http://gerrit.example.bogus:8081
                    Note that in all cases you must not specify the path to the file!
                    Be aware: this feature requires curl to be installed on your system/path!
  -x                When fetcthing the commit-msg file from 'hostname', add the hostname
                    to the no-proxy definition, thus bypassing the local proxy
  -p [remote]       push the changes after committing using the remote specified
  -b [branch]       use branch 'branch' on the remote repository as target when pushing
                    Depending if a Change Id was generated, it is automatically determined
                    if pushing shall be done for code review, or a direct push against
                    the branch of the repository shall be performed.
                    You may overwrite this, if you fully specify the branch's name including
                    all prefixes, i.e. refs/heads/master to force pushing directly to master
  -a                try to auto-submit the changes which are being pushed
  -r [options]      add receive-pack options when pushing (use quotes in case
                    you want to pass multiple options)

Note: Providing a commit message is mandatory, if you have specified the -c option

Options may appear multiple times on the command line; if used redundantly, the last 
value provided is considered to be the valid one.
EOT
}


# on getopts parsing see also http://wiki.bash-hackers.org/howto/getopts_tutorial
while getopts ":hu:e:scm:n:df:xp:b:ar:" opt; do
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
	d)
		COMMIT_DUMP=true
		;;
	f)
		FETCH_COMMIT_MSG=$OPTARG
		;;
	x)
		NO_PROXY=true
		;;
	p)
		REMOTE=$OPTARG
		;;
	b)
		BRANCH_AT_REMOTE=$OPTARG
		;;
	a)
		AUTO_SUBMIT=true
		;;
	r)
		RECEIVE_PACK_OPTIONS=$OPTARG
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


# ********************* Core Functions *******************


function sanity_checks {
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
}

function prepare_environment {
	# Set user configuration parameters
	if [ "$GIT_USERNAME" != "" ]; then
		echo "Setting local user name for commits to $GIT_USERNAME"
		git config --local --add user.name $GIT_USERNAME
	fi

	if [ "$GIT_EMAILADDRESS" != "" ]; then
		echo "Setting local email address for commits to $GIT_EMAILADDRESS"
		git config --local --add user.email $GIT_EMAILADDRESS
	fi

}

function stage_all {
	# Stage all changes if requested
	if [ "$STAGE_ALL" == "true" ]; then
		echo "Staging all changes..."
		git add --all || exit 1
	fi
}

function check_for_new_commit {
	echo "Checking if there is something to commit"
	git diff-index --quiet HEAD
	COMMIT_CHECK=$?
	if [ $COMMIT_CHECK == 0 ]; then
		echo "No changes to commit; nothing to do"
		exit 0
	fi
	echo "There are changes in the repository which will be committed:"
	git status -s

	if [ "$COMMIT_CHANGES" != "true" ]; then
		echo "Committing not requested; stop processing"
		exit 0
	fi
}

function fetch_commitmsg {
	if [ "$FETCH_COMMIT_MSG" != "" ]; then 
		echo "Checking, if commit-msg file needs to be fetched from server (or if it is already available locally)"
		if [ -x .git/hooks/commit-msg ]; then
			echo "commit-msg file is already available, skipping download"
		else
			echo "Downloading commit-msg from https://$FETCH_COMMIT_MSG/tools/hooks/commit-msg"
			rm -f .git/hooks/commit-msg
			
			local CURL_OPTIONS=""
			if [ "$NO_PROXY" == "true" ]; then
				# Strip the port away, if it was specified (sed does not touch the line, if no match was found)
				CURL_OPTIONS+=" --noproxy `echo $FETCH_COMMIT_MSG | sed -r 's/((ht|f)tps?://)?([^:]*):[0-9]*$/\1/' `"
			fi
			
			local FETCH_URL=""
			if [[ $FETCH_COMMIT_MSG =~ ^(ht|f)tps?:// ]]; then
				FETCH_URL=$FETCH_COMMIT_MSG
			else
				FETCH_URL=https://$FETCH_COMMIT_MSG
			fi
			
			curl $CURL_OPTIONS --insecure $FETCH_URL/tools/hooks/commit-msg > .git/hooks/commit-msg
			chmod +x .git/hooks/commit-msg
		fi
	fi

}

function commit {
	local GIT_OPTIONS=""

	if [ "$AUTOCRLF" != "" ]; then
		GIT_OPTIONS+=" -c core.autocrlf=$AUTOCRLF"
	fi

	if [ "$COMMIT_MESSAGE" != "" ]; then
		git $GIT_OPTIONS commit "--message=$COMMIT_MESSAGE"
	else
		echo "SHOULD NOT BE REACHED" >&2
		exit 255
	fi

	local GIT_COMMIT_RET=$?
	if [ $GIT_COMMIT_RET != 0 ]; then
		echo "ERROR: git commit stopped with error code $GIT_COMMIT_RET" >&2
		exit 1
	fi

	if [ "$COMMIT_DUMP" == "true" ]; then
		git log --max-count 1
	fi
}

function push {
	if [ "$REMOTE" != "" ]; then
		echo "Pushing changes to remote $REMOTE"

		# verify number of attempts
		
		local PUSH_OPTIONS=""
		if [ "$RECEIVE_PACK_OPTIONS" != "" ]; then
			PUSH_OPTIONS=--receive-pack=\"git receive-pack $RECEIVE_PACK_OPTIONS\"
		fi
		
		local REFSPEC=""
		if [ "$BRANCH_AT_REMOTE" != "" ]; then
		
			if [[ $BRANCH_AT_REMOTE =~ ^refs/ ]]; then
				REFSPEC+="HEAD:$BRANCH_AT_REMOTE"
			else
				local HAS_CHANGE_ID=`git log -1 | grep Change-Id: | wc -l`
				if [ $HAS_CHANGE_ID == 1 ]; then
					REFSPEC+="HEAD:refs/for/$BRANCH_AT_REMOTE"
					if [ "$AUTO_SUBMIT" == "true" ]; then
						REFSPEC+="%submit"
					fi
				else
					REFSPEC+="HEAD:refs/heads/$BRANCH_AT_REMOTE"
				fi
			fi
		fi
		echo "Using refspec $REFSPEC on pushing to $REMOTE"
		
		local TMPFILE=`mktemp`
		git push $PUSH_OPTIONS $REMOTE $REFSPEC 2>&1 | tee $TMPFILE
		
		local PUSH_RET=$?
		if [ $PUSH_RET == 0 ]; then
			return 0;
		fi
		
		# something failed; we need to analyze what went wrong
		if [ `cat $TMPFILE | grep -e 'remote rejected.*Internal server error' | wc -l` > 0 ]; then
			rm -f $TMPFILE
			echo "WARNING: Internal server error occured; trying to push again after 3 seconds"
			sleep 3
			return 129
		else
			echo "ERROR: git pushed failed with error code $PUSH_RET" >&2
			rm -f $TMPFILE
			exit 1
		fi
		rm -f $TMPFILE
	fi
	return 0
}

# ********************* Main Routine *******************

sanity_checks
prepare_environment

stage_all

check_for_new_commit

fetch_commitmsg

COUNT_PUSH=0

while true; do
	COUNT_PUSH=$[COUNT_PUSH+1]
	if [ $COUNT_PUSH > 3 ]; then
		echo "Number of push attempts exceeded; stopping execution"
		exit 1
	fi
	
	commit
	push
	
	local PUSH_RET=$?
	if [ $PUSH_RET == 0 ]; then
		break
	elif [ $PUSH_RET == 129 ]; then
		# undo the previous commit. The old Change-Id may be tainted.
		# The commit statement above will make sure that a new Change-Id is being drawn.
		git reset --mixed
	fi
done


exit 0

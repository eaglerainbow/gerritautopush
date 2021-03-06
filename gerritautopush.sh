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
                    (requires Gerrit server v2.7 or later)
  -r [options]      add receive-pack options when pushing (use quotes in case
                    you want to pass multiple options)
                    (deprecated -- newer versions of gerrit suggest not to use it)
  -o [email addr]   add email address to the notification email as the carbon-copy (CC)
                    when pushing to Gerrit server (v2.7 or later required)
                    Multi-addressing is possible by using the same parameter multiple times.
  -v [email addr]   add email address / user as reviewer to the Code Review
                    when pushing to Gerrit server (v2.7 or later required)
                    Multi-addressing is possible by using the same parameter multiple times.
  -g [location]     do not use git from the path, but use a given version
                    specified at 'location' (you need to specify the full path)
  -w [time]         waits an random value of seconds, up to 'time' seconds 
                    before pushing/submitting

Note: Providing a commit message is mandatory, if you have specified the -c option

Options may appear multiple times on the command line; if used redundantly, the last 
value provided is considered to be the valid one.
EOT
}

GERRIT_REVIEWER=()
GERRIT_CC=()

# on getopts parsing see also http://wiki.bash-hackers.org/howto/getopts_tutorial
while getopts ":hu:e:scm:n:df:xp:b:ar:g:w:o:v:" opt; do
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
	g)
		GIT_PROGRAM=$OPTARG
		;;
	w)
		RANDOM_WAIT=$OPTARG
		;;
	o)
		GERRIT_CC+=("$OPTARG")
		;;
	v)
		GERRIT_REVIEWER+=("$OPTARG")
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


if [ "$GIT_PROGRAM" == "" ]; then
	GIT_PROGRAM=git   # use the program that is available via path
fi

# ********************* Core Functions *******************


function sanity_checks {
	# Do sanity check before we start
	if [ ! -x .git ]; then
		echo "Local directory is not containing a git repository" >&2
		exit 1
	fi

	# Verify that we have a valid git executable
	local TMPFILE=`mktemp`
	$GIT_PROGRAM --version 2>&1 >$TMPFILE
	
	if [ $? != 0 ]; then
		echo "The git toolbox cannot be accessed at $GIT_PROGRAM"
		rm -f $TMPFILE	# don't forget the cleanup
		exit 1
	fi
	
	if [ `cat $TMPFILE | grep git | wc -l` == 0 ]; then
		echo "The git toolbox cannot be accessed at $GIT_PROGRAM"
		rm -f $TMPFILE	# don't forget the cleanup
		exit 1
	fi
	rm -f $TMPFILE
	
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
		$GIT_PROGRAM config --local --add user.name $GIT_USERNAME
	fi

	if [ "$GIT_EMAILADDRESS" != "" ]; then
		echo "Setting local email address for commits to $GIT_EMAILADDRESS"
		$GIT_PROGRAM config --local --add user.email $GIT_EMAILADDRESS
	fi

}

function stage_all {
	# Stage all changes if requested
	if [ "$STAGE_ALL" == "true" ]; then
		echo "Staging all changes..."
		$GIT_PROGRAM add --all || exit 1
	fi
}

function check_for_new_commit {
	echo "Checking if there is something to commit"
	$GIT_PROGRAM diff-index --quiet HEAD
	COMMIT_CHECK=$?
	if [ $COMMIT_CHECK == 0 ]; then
		echo "No changes to commit; nothing to do"
		exit 0
	fi
	echo "There are changes in the repository which will be committed:"
	$GIT_PROGRAM status -s

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
		$GIT_PROGRAM $GIT_OPTIONS commit "--message=$COMMIT_MESSAGE"
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
		$GIT_PROGRAM log --max-count 1
	fi
}

function getRefspecExtension {
	local ext=""

	if [ "$AUTO_SUBMIT" == "true" ]; then
		# see also http://gerrit-documentation.googlecode.com/svn/Documentation/2.7/user-upload.html#auto_merge
		ext+="submit"
	fi

	# see also https://review.openstack.org/Documentation/cmd-receive-pack.html
	if [ ${#GERRIT_CC[@]} != 0 ]; then
		local i 
		for ((i=0; i < ${#GERRIT_CC[@]}; i++)); do
			if [ "$ext" != "" ]; then
				ext+=","
			fi
			ext+="cc=${GERRIT_CC[i]}"
		done
	fi

	if [ ${#GERRIT_REVIEWER[@]} != 0 ]; then
		local i 
		for ((i=0; i < ${#GERRIT_REVIEWER[@]}; i++)); do
			if [ "$ext" != "" ]; then
				ext+=","
			fi
			ext+="r=${GERRIT_REVIEWER[i]}"
		done
	fi
	
	echo "$ext"
}

function dopush {
	if [ "$REMOTE" != "" ]; then
		echo "Pushing changes to remote $REMOTE"

		local PUSH_OPTIONS=""
		if [ "$RECEIVE_PACK_OPTIONS" != "" ]; then
			# QUALMS! We know that this approach is quite broken:
			# The RECEIVE_PACK_OPTIONS are passed together in one junk to the git
			# command. That leads to the problem that the entire string
			# "git receive-pack xyz" is passed to the remote git server is one
			# single command. The gerrit server then searches for a single file
			# called "git receive-pack xyz" and thus won't be able to find anything
			# (as the command just called "git" only).
			# However, as setting receive-pack options anyhow are considered to be
			# deprecated for gerrit servers, this issue has not been fixed, yet.
			PUSH_OPTIONS='--receive-pack="git receive-pack '$RECEIVE_PACK_OPTIONS'"'
		fi
		
		local REFSPEC=""
		if [ "$BRANCH_AT_REMOTE" != "" ]; then
			if [[ $BRANCH_AT_REMOTE =~ ^refs/ ]]; then
				REFSPEC+="HEAD:$BRANCH_AT_REMOTE"
			else
				local HAS_CHANGE_ID=`$GIT_PROGRAM log -1 | grep Change-Id: | wc -l`
				if [ $HAS_CHANGE_ID == 1 ]; then
					REFSPEC+="HEAD:refs/for/$BRANCH_AT_REMOTE"
					
					local extension=""
					# for idea of ret-value, see also http://www.linuxjournal.com/content/return-values-bash-functions
					extension=$(getRefspecExtension)
					
					if [ "$extension" != "" ]; then
						REFSPEC+="%$extension"
					fi
				else
					REFSPEC+="HEAD:refs/heads/$BRANCH_AT_REMOTE"
				fi
			fi
		fi
		echo "Using refspec $REFSPEC on pushing to $REMOTE"
		
		if [ "$RANDOM_WAIT" != "" ]; then
			waittime=$RANDOM
			waittime=$((waittime % RANDOM_WAIT))
			echo "waiting for $waittime seconds before continuing"
			sleep $waittime
		fi
		
		local TMPFILE=`mktemp`
		
		if [ "$PUSH_OPTIONS" == "" ]; then
			$GIT_PROGRAM push $REMOTE $REFSPEC 2>&1 | tee $TMPFILE
		else
			$GIT_PROGRAM push "$PUSH_OPTIONS" $REMOTE $REFSPEC 2>&1 | tee $TMPFILE
		fi
		
		local PUSH_RET=${PIPESTATUS[0]}
		# idea: see http://unix.stackexchange.com/questions/14270/get-exit-status-of-process-thats-piped-to-another/73180#73180 
		if [ $PUSH_RET == 0 ]; then
			return 0
		fi
		
		# something failed; we need to analyze what went wrong
		if [ `cat $TMPFILE | grep -e 'remote rejected.*Internal server error' | wc -l` -gt 0 ] && [ $AUTO_SUBMIT == "true" ]; then
			rm -f $TMPFILE
			echo "WARNING: Internal server error occured; trying to push again after 3 seconds"
			sleep 3
			return 129
		else
			echo "ERROR: git pushed failed with error code $PUSH_RET" >&2
			rm -f $TMPFILE
			exit 1 # NB: Not just "return" but "exit" to stop script execution!
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

commit

COUNT_PUSH=0

while true; do
	COUNT_PUSH=$[COUNT_PUSH+1]
	# verify number of attempts
	if [ $COUNT_PUSH -gt 3 ]; then
		echo "Number of push attempts exceeded; stopping execution"
		exit 1
	fi
	
	dopush
	PUSH_RET=$?
	if [ $PUSH_RET == 0 ]; then
		break
	elif [ $PUSH_RET == 129 ]; then
		# as described at http://gerrit-documentation.googlecode.com/svn/Documentation/2.7/user-upload.html#auto_merge
		# triggering the execution of "submit" may be done with the same command and does
		# not require to draw a new Change-Id
		continue
	fi
done


exit 0

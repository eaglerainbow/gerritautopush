gerritautopush
==============

Gerritautopush.sh helps you automating to commit changes of files to a git repository and push&submit those changes to a Gerrit/git server. it is especially suited to run in a batch environment, such as a Jenkins job.

# Prerequisites
* You need to have a git command-line tool installed (such as under Windows: msysgit).
* You need to have a bash-compatible environment available (usually available on Linux maschines out-of-the-box, available in many git command-line packages, such as msysgit).
* If you want to use this script together with a Gerrit server and want to make use of the auto-submit feature, you need to run Gerrit server v2.7 or later.

# Features
* four modes available
  * only staging
  * only staging and committing
  * staging, committing and pushing
  * staging, committing, pushing and auto-submitting
* on committing
  * works even in detached-HEAD mode (usually the mode in which Jenkins jobs are executed)
  * provide custom message text (one-liner)
  * allow setting core.autocrlf mode via command-line parameter
  * verifying what has been committed
  * automated retrieval of commit-msg file from gerrit server for auto-generating new Change-Id properties in the commit message.
  * bypassing of proxy configuration for approaching the gerrit server on retrieving the commit-msg file
* on pushing
  * custom selection of the target branch in the remote repository
  * try to immediately submit the Code Review (with Verified+1 and CodeReview+2) on pushing
  * enrich call to receive-pack with additional custom parameters (for instance allows adding additional CC receivers to the Gerrit Code Review emails)
  * automated recovery on "internal server error" issue by creating a new Change-Id and trying to push once again
* Miscellaneous
  * Setting the user name to be used for committing in the repository locally
  * Setting the email address to be used for committing in the repository locally

# Installation
Copy the file gerritautopush.sh to any location on your maschine. If you place it into some directory which is part of your PATH environment variable, you may use it in any arbitrary directory.

# Usage
Start the script by calling it via the command-line as usual.
Provide the parameter -h to see the current help&usage documentation (built into the script).

As of writing, this is the usage documentation provided:
```
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
```

# Example
A very typical usage with staging, committing and pushing is written like this:
```
gerritautopush.sh -s -c -m "This is the commit message" -f gerritserver.example.bogus -p origin -b master
```
This will
* stage all changes in the current directory
* commit the changes using the commit message `This is the commit message`
* The commit-msg file is retrieved from http://gerritserver.example.bogus/tools/hooks/commit-msg, which will enable the generation of a new Change-Id for the commit
* push the commit for review to branch `master` using the configuration provided by remote `origin`

# Execution of automated Tests
Change to the directory "test", which is available in this repository.
Run script ./runtests.sh there.

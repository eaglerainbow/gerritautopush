gerritautopush
==============

Gerritautopush.sh allows you to automate to commit changes of files to a git repository and push&submit those changes to a Gerrit/git server. it is especially suited to run in a batch environment, such as a Jenkins job.

# Prerequisites
* You need to have a git command-line tool installed (such as under Windows: msysgit)
* You need to have a bash-compatible environment available (usually available on Linux maschines out-of-the-box, available in many git command-line packages, such as msysgit)

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
  * enrich call to receive-pack with additional custom parameters (for instance allows adding additional CC reecivers to the Gerrit Code Review emails)
* Miscellaneous
  * Setting the user name to be used for committing in the repository locally
  * Setting the email address to be used for committing in the repository locally

# Installation
tbd

# Usage
tbd

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

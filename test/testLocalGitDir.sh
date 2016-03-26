#!/bin/bash


. ./infra.inc

echo "*** Running test LocalGitDir"

export GIT_CMD="$PWD/mockGitSimple.sh"

rm -rf localgitdir
mkdir localgitdir && cd localgitdir
createSimpleRepo

$SUBJECT -u testuser -e someuser@example.bogus

if [ $? != 0 ]; then
	echo "ERROR: Non-zero exit on test"
	exit 1
fi

export GIT_CMD=""

if [ `git config --list | grep "user.email=someuser@example.bogus" | wc -l` != 1 ]; then
	echo "ERROR: Email address was not set properly; configuration parameter are as follows:"
	git config --list
	exit 1
fi

if [ `git config --list | grep "user.name=testuser" | wc -l` != 1 ]; then
	echo "ERROR: Username was not set properly; configuration parameter are as follows:"
	git config --list
	exit 1
fi

cd ..
rm -rf localgitdir


#!/bin/bash


. ./infra.inc
TESTDIR=pushWithReviewerMultiple

echo "*** Running test Push including multiple reviewers"

rm -rf $TESTDIR
mkdir $TESTDIR && cd $TESTDIR

mkdir remote && cd remote
createBareRepo
cd ..

mkdir local && cd local
cloneRepo ../remote

# we need to write something to the remote repository, otherwise this won't do the trick...
echo "test" > dummy.txt
git add dummy.txt
git commit -m "dummy commit message"
git push origin

# we need another entry, which the script may now commit
echo "test2" >dummy2.txt

# Note: "Change-Id:" is necessary to activate the gerrit-mode!
$SUBJECT -s -c -m "Change-Id:  dummy commit message" -p origin -b master -v dummyuser@example.bogus -v dummyuser2@example.bogus -g $PWD/../../git_push_reviewer_multiple.sh

if [ $? != 0 ]; then
	echo "ERROR: Non-zero exit on test"
	exit 1
fi

cd ../remote

if [ `git log --max-count 1 | grep "dummy commit message" | wc -l` != 1 ]; then
	echo "ERROR: new commit was not pushed to the remote repository; state of the remote repository:"
	git log
	exit 1
fi 

cd ..

cd ..
rm -rf $TESTDIR


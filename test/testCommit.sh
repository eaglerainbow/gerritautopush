#!/bin/bash


. ./infra.inc
TESTDIR=commit

echo "*** Running test Commit -- positive test - standard"

export GIT_CMD="$PWD/mockGitSimple.sh"

rm -rf $TESTDIR
mkdir $TESTDIR && cd $TESTDIR
createSimpleRepo

echo "test" > dummy.txt

$SUBJECT -s -c -m "dummy commit message"

if [ $? != 0 ]; then
	echo "ERROR: Non-zero exit on test"
	exit 1
fi

export GIT_CMD=""

if [ `git status -s | grep "A  dummy.txt" | wc -l`  != 0  ]; then
	echo "ERROR: stuff is still staged, even after committing; this is the status of the current git repo:"
	git status
	exit 1
fi

cd ..
rm -rf $TESTDIR

echo "*** Running test Commit -- positive test - verify that dumping commit works"

export GIT_CMD="$PWD/mockGitSimple.sh"

rm -rf $TESTDIR
mkdir $TESTDIR && cd $TESTDIR
createSimpleRepo

echo "test" > dummy.txt

$SUBJECT -s -c -m "dummy commit message" -d >log.tmp

if [ $? != 0 ]; then
	echo "ERROR: Non-zero exit on test"
	exit 1
fi

export GIT_CMD=""

CHECK=`cat log.tmp | grep "   dummy commit message" | wc -l`
if [ "$CHECK" != 1 ]; then
	echo "ERROR: commit message was not dumped to the console"
	cat log.tmp
	exit 1
fi

# cleanup again
rm log.tmp

cd ..
rm -rf $TESTDIR


echo "*** Running test Commit -- negative test; missing commit message"

export GIT_CMD="$PWD/mockGitSimple.sh"

rm -rf $TESTDIR
mkdir $TESTDIR && cd $TESTDIR
createSimpleRepo

echo "test" > dummy.txt

# Note: Commit Message is missing
$SUBJECT -s -c 

if [ $? != 1 ]; then
	echo "ERROR: zero exit on test"
	exit 1
fi

export GIT_CMD=""

if [ `git status -s | grep "A  dummy.txt" | wc -l`  != 0  ]; then
	echo "ERROR: stuff has been staged although call is inconsistent:"
	exit 1
fi


cd ..
rm -rf $TESTDIR


echo "*** Running test Commit -- positive test - verify that autocrlf has been passed along"

export MOCK_RESPONSE=`mktemp`
export GIT_CMD="$PWD/mockGitAutoCRLF.sh"

rm -rf $TESTDIR
mkdir $TESTDIR && cd $TESTDIR
createSimpleRepo

echo "test" > dummy.txt

$SUBJECT -s -c -m "dummy commit message" -n true

if [ $? != 0 ]; then
	echo "ERROR: Non-zero exit on test"
	exit 1
fi

if [ `cat $MOCK_RESPONSE | grep -c -e ".c core.autocrlf=true" ` != 1 ]; then
	echo "ERROR: autocrlf option was not provided properly"
	rm -f $MOCK_RESPONSE
	exit 1
fi

export GIT_CMD=""
rm -f $MOCK_RESPONSE

if [ `git status -s | grep "A  dummy.txt" | wc -l`  != 0  ]; then
	echo "ERROR: stuff is still staged, even after committing; this is the status of the current git repo:"
	git status
	exit 1
fi

cd ..
rm -rf $TESTDIR

echo "*** Running test Commit -- negative test - proper reaction on commit failure"

export GIT_CMD="$PWD/mockGitCommitFailure.sh"

rm -rf $TESTDIR
mkdir $TESTDIR && cd $TESTDIR
createSimpleRepo

echo "test" > dummy.txt

$SUBJECT -s -c -m "dummy commit message"

if [ $? == 0 ]; then
	echo "ERROR: Non-zero exit expected, but got $?"
	exit 1
fi
echo "Note: If you see an error message above, this is intended!"

export GIT_CMD=""
rm -f $MOCK_RESPONSE

cd ..
rm -rf $TESTDIR
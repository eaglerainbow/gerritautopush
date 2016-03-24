#!/bin/bash


. ./infra.inc
TESTDIR=commit

echo "*** Running test Commit -- positive test"

rm -rf $TESTDIR
mkdir $TESTDIR && cd $TESTDIR
createSimpleRepo

echo "test" > dummy.txt

$SUBJECT -s -c -m "dummy commit message"

if [ $? != 0 ]; then
	echo "ERROR: Non-zero exit on test"
	exit 1
fi

if [ `git status -s | grep "A  dummy.txt" | wc -l`  != 0  ]; then
	echo "ERROR: stuff is still staged, even after committing; this is the status of the current git repo:"
	git status
	exit 1
fi

echo "*** Running test Commit -- negative test; missing commit message"

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

if [ `git status -s | grep "A  dummy.txt" | wc -l`  != 0  ]; then
	echo "ERROR: stuff has been staged although call is inconsistent:"
	exit 1
fi


cd ..
rm -rf $TESTDIR


#!/bin/bash


. ./infra.inc
TESTDIR=push

echo "*** Running test Push -- positive test - standard"

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
git commit -m "first commit"
git push origin

# we need another entry, which the script may now commit
echo "test2" >dummy2.txt

$SUBJECT -s -c -m "dummy commit message" -p origin

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


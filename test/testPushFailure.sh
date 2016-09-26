#!/bin/bash


. ./infra.inc
TESTDIR=pushfailure

echo "*** Running test Push -- negative test - standard"

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

$SUBJECT -s -c -m "dummy commit message" -p origin -g $PWD/../../git_push_failure.sh

if [ $? == 0 ]; then
	echo "ERROR: failing pushes are not propagated properly"
	exit 1
fi

cd ..

cd ..
rm -rf $TESTDIR


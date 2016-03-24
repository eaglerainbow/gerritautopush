#!/bin/bash


. ./infra.inc

echo "*** Running test StageAll"

rm -rf stageall
mkdir stageall && cd stageall
createSimpleRepo

echo "test" > dummy.txt

$SUBJECT -s

if [ $? != 0 ]; then
	echo "ERROR: Non-zero exit on test"
	exit 1
fi

if [ `git status -s | grep "A  dummy.txt" | wc -l`  != 1  ]; then
	echo "ERROR: auto-stating did not work; this is the status of the current git repo:"
	git status
fi

cd ..
rm -rf stageall


#!/bin/bash

. ./infra.inc

echo "*** Running test Simple"

export GIT_CMD="$PWD/mockGitSimple.sh"

rm -rf simple
mkdir simple && cd simple
createSimpleRepo

$SUBJECT 

if [ $? != 0 ]; then
	echo "ERROR: Non-zero exit on empty call"
	exit 1
fi

export GIT_CMD=""

cd ..
rm -rf simple


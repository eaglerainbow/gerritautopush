#!/bin/bash


. ./infra.inc

echo "*** Running negative test other git tool"

rm -rf othergit
mkdir othergit && cd othergit
createSimpleRepo

$SUBJECT -g ../dummygit.sh

if [ $? == 0 ]; then
	echo "ERROR: zero exit on test"
	exit 1
fi

if [ ! -f 'dummygit.tmp' ]; then
	echo "Dummygit tool was not called"
	exit 1
fi


cd ..
rm -rf othergit


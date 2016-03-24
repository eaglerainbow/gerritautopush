#!/bin/bash


. ./infra.inc

echo "*** Running test help"

rm -rf help
mkdir help && cd help

# no repo required!

RETV=`$SUBJECT -h | grep usage | wc -l`

if [ $? != 0 ]; then
	echo "ERROR: Non-zero exit on test"
	exit 1
fi

if [ "$RETV" != "1" ]; then
	echo "ERROR: Usage text was not printed properly"
	exit 1
fi
cd ..
rm -rf help


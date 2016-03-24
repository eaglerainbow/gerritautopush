#!/bin/bash

. ./infra.inc

echo "Running test Simple"

rm -rf simple
mkdir simple && cd simple
$SUBJECT 

if [ $? != 0 ]; then
	echo "ERROR: Non-zero exit on empty call"
	exit 1
fi



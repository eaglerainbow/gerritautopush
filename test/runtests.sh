#!/bin/bash


export SUBJECT=$PWD/../gerritautopush.sh
echo "Script under test: $SUBJECT"


./testSimple.sh || exit 1
./testHelp.sh || exit 1
./testLocalGitDir.sh || exit 1
./testStageAll.sh || exit 1
./testCommit.sh || exit 1



#!/bin/bash

function createSimpleRepo {
	OLDDIR=$PWD
	mkdir $1
	cd $1
	git init .
	cd $OLDDIR
}

function createBareRepo {
	OLDDIR=$PWD
	mkdir $1
	cd $1
	git init --bare .
	cd $OLDDIR
}


function linkToBareRepo {
	git remote add origin file:///$1
}



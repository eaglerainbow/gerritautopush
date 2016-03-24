#!/bin/bash

function createSimpleRepo {
	git init .
}

function createBareRepo {
	git init --bare .
}


function linkToBareRepo {
	git remote add origin file:///$1
}



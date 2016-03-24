#!/bin/bash

function createSimpleRepo {
	git init .
	git commit -m "initial empty commit" --allow-empty
}

function createBareRepo {
	git init --bare .
}


function linkToBareRepo {
	git remote add origin file:///$1
}



#!/bin/bash

function createSimpleRepo {
	git init .
	git commit -m "initial empty commit" --allow-empty
}

function createBareRepo {
	git init --bare .
}


function cloneRepo {
	git clone $1 .
	git config --local push.default simple
}



#!/bin/bash

if [ ! -d node_modules/jquery ]
then
	echo "to build you must run:"
	echo "$ npm install jquery"
	echo "and maybe more modules, errors of coffeescript compiler will let you know ;)"
	exit 1
fi

coffee -b -p -j -c coffeescripts/*.coffee |grep -v require\( > tb_label.js

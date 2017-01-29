#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "No arguments supplied. Usage ./runmorbo.sh <port>"
  else
	echo $1
	morbo -l "http://*:$1" camshotbot.pl -w camshotbot.conf
fi

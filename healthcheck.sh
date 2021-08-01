#!/bin/bash

while [ $(cat /status) != "INIT" ]
do
	sleep 10;
done

curl --insecure --fail --silent --show-error -I http://localhost:80 > /dev/null || exit 1

#!/usr/bin/env bash
audio=$1
sox $1 -t raw -c 1 -b 16 -r 16k -e signed-integer - | \
    tee >(play -t raw -r 16k -e signed-integer -b 16 -c 1 -q -) | \
    pv -L 16000 -q | nc -N localhost 5050
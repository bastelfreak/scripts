#!/bin/bash

##
# written by canta (dhxgit)
##

shellcheck -e"$(shellcheck $(ls * */*) 2>/dev/null | grep -o "SC[0-9]\{4\}" | sort | uniq | paste -sd, | grep -v $1)" $(ls * */*)

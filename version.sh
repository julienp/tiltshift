#!/bin/sh
echo `git describe --abbrev=0` "("`git log --pretty=oneline|wc -l|tr -d ' '`")"

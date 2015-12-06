#!/bin/sh

find . -name "*.log" -o -name "*.acc2" | tar -zcf results.tar.gz -T -

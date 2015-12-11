#!/bin/sh

find . -name "*.log" | tar -zcf results.tar.gz -T -

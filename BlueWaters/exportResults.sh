#!/bin/sh

perl export_results.pl | tar -zcf results.tar.gz -T -

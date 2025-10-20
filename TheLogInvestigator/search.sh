#!/bin/bash env 

cat app.log 

grep -i "ERROR" ~/project/logs/app.log > ~/project/error_report.txt



#!/bin/bash

./getPodId.py $1 |json2yaml |grep -i podid|awk '{print $NF}'

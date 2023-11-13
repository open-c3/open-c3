#!/bin/bash

./ListJobs.py |json2yaml |grep JobId|awk '{print $NF}'|grep dlc

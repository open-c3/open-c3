#!/bin/bash

./getPodId.py $1 |json2yaml |egrep "DisplayName:|Image:" |grep -v AIMasterDockerImage|sed 's/^ *//'

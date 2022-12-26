#!/bin/bash
env LANG=LC_ALL grep -nrP 'uib-tooltip="[\x81-\xFE][\x40-\xFE]' .. |grep -v '|translate}}'
#sed -i "s/uib-tooltip=\"机器管理\"/uib-tooltip=\"{{'C3T.机器管理'|translate}}\"/g" `grep 'uib-tooltip="机器管理"' -rl .`

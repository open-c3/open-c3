#!/bin/bash
set -e

echo '{"name":"wfww","sex":"man"}' | ./c3mc-bpm-display-field-values name,sex
echo '{"name":"wfww","sex":"man"}' | ./c3mc-bpm-display-field-values "姓名是: {name}, 性别是: {sex}"
echo '{"name":"wfww","vpc": {"id": "xxx"}}' | ./c3mc-bpm-display-field-values "姓名是: {name}, 性别是: {sex}, vpc.id为: {vpc[id]}"
# 子字段支持无限层级
echo '{"name":"wfww","vpc": {"id": {"index": 2}}}' | ./c3mc-bpm-display-field-values "姓名是: {name}, vpc.id.index为: {vpc[id][index]}"

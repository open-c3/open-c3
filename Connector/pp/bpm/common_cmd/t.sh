#!/bin/bash
set -e

echo '{"name":"wfww","sex":"man"}' | ./c3mc-bpm-display-field-values name,sex
echo '{"name":"wfww","sex":"man"}' | ./c3mc-bpm-display-field-values "姓名是: {name}, 性别是: {sex}"

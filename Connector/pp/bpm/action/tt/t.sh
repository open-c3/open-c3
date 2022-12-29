#!/bin/bash
set -e

# submit_user可以不用传，默认为 sys@app

echo "{\"content\":\"wfe\",\"title\":\"域名申请与解析\", \"submit_user\": \"someone@gmail.com\"}" | ./c3mc-bpm-action-tt 

echo "{\"content\":\"wfe\",\"title\":\"域名申请与解析\"}" | ./c3mc-bpm-action-tt

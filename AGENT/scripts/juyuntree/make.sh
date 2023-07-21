#!/bin/bash

mkdir -p treemap 
curl -H 'appname: openc3' -H 'appkey: xxxxxx' https://console.polymericcloud.com/api/keystone/platform/allservicetree > treemap/allservicetree

mkdir -p nodeinfo
cat treemap/allservicetree | json2yaml | grep '^\- id: [0-9]*$' | awk '{print $NF}' | xargs -i{} bash -c "curl  -H 'appname: openc3' -H 'appkey: xxxxxx'  https://console.polymericcloud.com/api/platform/c3/serviceTree/node/{} > nodeinfo/{}"


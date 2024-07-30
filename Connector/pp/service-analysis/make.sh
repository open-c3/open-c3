
#!/bin/bash
set -e

cd /data/Software/mydan/Connector/pp/service-analysis || exit;

ls */make|awk -F/ '{print $1}'|xargs -i{} bash -c "cd {} && ./make > data.txt.tmp && mv data.txt.tmp data.txt"

./analysis |sed 's/\s+/ /g' |sed 's/\t/ /g' > tree.data.temp

mv tree.data.temp /data/open-c3-data/device/curr/serviceanalysis.tree.data


#!/bin/bash
set -e

./analysis |sed 's/\s+/ /g' |sed 's/\t/ /g' > tree.data.temp

mv tree.data.temp /data/open-c3-data/device/curr/serviceanalysis.tree.data

#!/bin/bash

#!/bin/bash
set -e

cd /data/open-c3/Connector/bl
bash build.sh

chmod +x ./c3mc-create-ticket
mkdir -p /data/open-c3/Connector/pp/bl
mv c3mc-create-ticket /data/open-c3/Connector/pp/bl

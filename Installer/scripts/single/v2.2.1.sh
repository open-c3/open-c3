#!/bin/bash

docker exec -i c3_openc3-server_1 /data/Software/mydan/perl/bin/cpan install AnyEvent::HTTPD::Router AnyEvent::HTTPD::CookiePatch

docker cp /data/open-c3/Installer/install-cache/bin/kubectl  c3_openc3-server_1:/usr/bin/
docker cp /data/open-c3/Installer/install-cache/bin/yaml2json  c3_openc3-server_1:/usr/bin/
docker cp /data/open-c3/Installer/install-cache/bin/json2yaml  c3_openc3-server_1:/usr/bin/

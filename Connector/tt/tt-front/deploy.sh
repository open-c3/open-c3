#!/bin/bash

rm -rf dist
./dev.sh build
mkdir -p   /data/open-c3/Installer/install-cache/trouble-ticketing/tt-front
rm -rf     /data/open-c3/Installer/install-cache/trouble-ticketing/tt-front/dist
cp -r dist /data/open-c3/Installer/install-cache/trouble-ticketing/tt-front/dist

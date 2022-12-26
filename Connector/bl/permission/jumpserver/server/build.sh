#!/bin/bash
set -e

go build -o jumpserver-server
mv jumpserver-server /usr/bin

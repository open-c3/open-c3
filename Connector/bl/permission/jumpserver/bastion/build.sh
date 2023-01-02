#!/bin/bash
set -e

go build -o jumpserver-bastion
mv jumpserver-bastion /usr/bin

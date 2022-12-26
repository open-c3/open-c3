#!/bin/bash

rm -rf http_load-12mar2006*

wget http://soft.vpser.net/test/http_load/http_load-12mar2006.tar.gz
tar -zxvf http_load-12mar2006.tar.gz
bash -c "cd http_load-12mar2006 && make"

cp http_load-12mar2006/http_load .

rm -rf http_load-12mar2006*

#!/bin/bash

cd $(dirname $0)

nohup  /data/Software/mydan/python3/bin/uvicorn app.main:app --reload  --host 0.0.0.0 --port 8000 &

#!/bin/bash
lsof -i:8000|grep uvicorn|awk '{print $2}'|xargs -i{} kill {}

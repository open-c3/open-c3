#!/bin/bash
lsof -i:8000|awk '{print $2}'|grep -v PID |xargs -i{} kill -9 {}

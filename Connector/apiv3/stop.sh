#!/bin/bash
lsof -i:7999|awk '{print $2}'|grep -v PID |xargs -i{} kill -9 {}

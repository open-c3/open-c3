#!/bin/bash

BASE_PATH=/data/open-c3
cd $BASE_PATH || exit 1

function list() {
    echo =================================================================
    echo "[INFO]git fetch ..."

    git branch -r |grep origin/v| grep -v "\->" | while read remote; do git branch --track "${remote#origin/}" "$remote"; done
    git fetch --all && git pull --all
}

function switch() {
    version=$1
    echo =================================================================
    echo "[INFO]switch to $version ..."

    git checkout $version

    echo "[SUCC]switch done."
}

case "$1" in
list)
    list
    ;;
switch)
    switch $2
    ;;
*)
    echo "Usage: $0 {list|switch}"
    echo "$0 switch v1.x.x"
    exit 2
esac

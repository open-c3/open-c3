#!/bin/bash

ID=$(git ls-remote https://github.com/open-c3/open-c3.github.io.git HEAD|awk '{print $1}')
echo https://github.com/open-c3/open-c3.github.io/commit/$ID

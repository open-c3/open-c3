#!/bin/bash
env LANG=LC_ALL grep -nrP '[\x81-\xFE][\x40-\xFE]' * |grep -v '|translate}}'

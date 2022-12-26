#!/bin/bash
env LANG=LC_ALL grep -nrP 'placeholder="[\x81-\xFE][\x40-\xFE]' .. |grep -v '|translate}}'

#!/bin/bash

c3mc-base-db-get -t openc3_ci_project groupid  -f 'status=1'          | grep -v '^0$' | sort | uniq | xargs -i{} ./diff.pl {}
c3mc-base-db-get -t openc3_job_jobs projectid -f "status='permanent'" | grep -v '^0$' | sort | uniq | xargs -i{} ./diff.pl {}

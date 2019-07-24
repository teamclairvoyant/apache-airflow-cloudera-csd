#!/bin/bash -x
su -s /bin/bash - airflow -c 'exec airflow scheduler'
#su -s /bin/bash - airflow -c 'exec airflow scheduler -n ${SCHEDULER_RUNS}'
#runuser -s /bin/bash -l -u airflow -c 'exec airflow scheduler'

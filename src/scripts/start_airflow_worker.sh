#!/bin/bash -x
su -s /bin/bash - airflow -c 'exec airflow worker'
#runuser -s /bin/bash -l -u airflow -c 'exec airflow worker'

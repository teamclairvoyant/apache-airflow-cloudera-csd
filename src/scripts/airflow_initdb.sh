#!/bin/bash -x
su -s /bin/bash - airflow -c 'exec airflow initdb'
#runuser -s /bin/bash -l -u airflow -c 'exec airflow initdb'

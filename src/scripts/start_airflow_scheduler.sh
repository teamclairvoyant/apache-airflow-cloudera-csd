#!/bin/bash
su -s /bin/bash - airflow -c 'exec airflow scheduler'
#runuser -s /bin/bash -l -u airflow -c 'exec airflow scheduler'

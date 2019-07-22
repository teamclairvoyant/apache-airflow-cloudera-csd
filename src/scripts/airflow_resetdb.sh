#!/bin/bash
su -s /bin/bash - airflow -c 'exec airflow resetdb -y'
#runuser -s /bin/bash -l -u airflow -c 'exec airflow resetdb -y'

#!/bin/bash -x
for pid in `ps -ef | grep -v "grep" | grep "airflow scheduler" | awk '{print $2}'` ; do kill -9 $pid || true ; done

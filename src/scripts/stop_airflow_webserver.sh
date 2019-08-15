#!/bin/bash -x
for pid in `ps -ef | grep "airflow webserver" | awk '{print $2}'` ; do kill -s TERM $pid || true ; done
sleep 3
for pid in `ps -ef | grep "airflow-webserver" | awk '{print $2}'` ; do kill -s KILL $pid || true ; done

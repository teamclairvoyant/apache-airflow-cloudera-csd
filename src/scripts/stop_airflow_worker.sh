#!/bin/bash
for pid in `ps -ef | grep -v "grep" | grep "airflow worker" | awk '{print $2}'` ; do kill -9 $pid || true ; done
for pid in `ps -ef | grep -v "grep" | grep "celery" | awk '{print $2}'` ; do kill -9 $pid || true ; done
for pid in `ps -ef | grep -v "grep" | grep "serve_log" | awk '{print $2}'` ; do kill -9 $pid || true ; done

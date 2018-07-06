for pid in `ps -ef | grep "airflow webserver" | awk '{print $2}'` ; do kill -9 $pid || true ; done
for pid in `ps -ef | grep "airflow-webserver" | awk '{print $2}'` ; do kill -9 $pid || true ; done

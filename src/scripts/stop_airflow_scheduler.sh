<<<<<<< HEAD
=======
#!/bin/bash -x
>>>>>>> 11b39ebe4b384d6ad1c1735474123e5af2c8676a
for pid in `ps -ef | grep -v "grep" | grep "airflow scheduler" | awk '{print $2}'` ; do kill -9 $pid || true ; done

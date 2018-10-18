sudo -Eu airflow bash -c 'export PATH=${AIRFLOW_DIR}/usr/bin:$PATH;
export PYTHONPATH=${AIRFLOW_DIR}/usr/lib/python2.7/site-packages:$PYTHONPATH; 
exec airflow resetdb -y'
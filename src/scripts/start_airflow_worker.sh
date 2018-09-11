export PATH=${AIRFLOW_DIR}/usr/local/bin:$PATH
sudo -Eu airflow bash -c 'cd ${AIRFLOW_DIR}/usr/local/bin/; exec ./airflow worker'
if [[ ${security} == "kerberos" ]]; then
	airflow kerberos
fi

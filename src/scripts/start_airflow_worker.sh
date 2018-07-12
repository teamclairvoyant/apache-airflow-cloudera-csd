su - airflow -c 'exec airflow worker'
if [[ ${security} == "kerberos" ]]; then
	airflow kerberos
fi

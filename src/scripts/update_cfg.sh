#!/bin/bash

mkdir -p ${airflow_home}/logs
mkdir ${airflow_home}/dags
chown -R airflow:airflow ${airflow_home}

if [ ! -f ${airflow_home}/airflow.cfg ]; then
  sudo -Eu airflow bash -c 'cd ${AIRFLOW_DIR}/usr/local/bin; ./airflow initdb'
  rm -rf ${AIRFLOW_DIR}/unittests.cfg
fi

MYSQL_PORT=3306
PGSQL_PORT=5432

if [ "$dbType" == "mysql" ]; then
    sql_alchemy_conn="mysql://${dbUser}:${dbPass}\@${dbHost}:${MYSQL_PORT}/airflow"
elif [ "$dbType" == "postgresql" ]; then
    sql_alchemy_conn="postgresql+psycopg2://${dbUser}:${dbPass}\@${dbHost}:${PGSQL_PORT}/airflow"
fi

PWCMD='< /dev/urandom tr -dc A-Za-z0-9 | head -c 20;echo'
secret_key=`eval $PWCMD`
fernet_key2=`cd ${AIRFLOW_DIR}/usr/local/bin; ./python2.7 -c 'from cryptography.fernet import Fernet;key=Fernet.generate_key().decode();print key'`


function replace {
    perl -pi -e "s#${1}#${2}#g" $3
}

while read line; do
    key=$(cut -d '=' -f1 <<< "$line" | xargs)
    value=$(cut -d '=' -f2 <<< "$line")
    if [[ ${!key} ]]; then
        if [[ "$key" != "#" ]]; then
            replace "$key =${value}" "$key = ${!key}" ${airflow_home}/airflow.cfg
        fi
    fi
done < ${airflow_home}/airflow.cfg

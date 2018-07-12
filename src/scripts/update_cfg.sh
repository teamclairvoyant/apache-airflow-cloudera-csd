#!/bin/bash

mkdir -p ${airflow_home}

cp ../scripts/airflow/airflow.cfg ${airflow_home}/
# install -o airflow -g airflow -m0644 ../scripts/airflow/airflow.cfg ${airflow_home}/

MYSQL_PORT=3306
PGSQL_PORT=5432

if [ "$dbType"=="mysql" ]; then
    DBCONNSTRING="mysql://${dbUser}:${dbPass}\@${dbHost}:${MYSQL_PORT}/airflow"
elif [ "$dbType"=="postgresql" ]; then
    DBCONNSTRING="postgresql+psycopg2://${dbUser}:${dbPass}\@${dbHost}:${PGSQL_PORT}/airflow"
fi

function replace {
    perl -pi -e "s#${1}#${2}#g" $3
}

function prepare_airflow_cfg {
    sql_alchemy_conn=DBCONNSTRING
    while read line; do
        key=$(cut -d '=' -f1 <<< "$line" | xargs)
        value=$(cut -d '=' -f2 <<< "$line")
        if [[ ${!key} ]]; then
            if [[ "$key" != "#" ]]; then
                replace "$key =${value}" "$key = ${!key}" ${airflow_home}/airflow.cfg
            fi
        fi
    done < ${airflow_home}/airflow.cfg

}

prepare_airflow_cfg

python="python"
if [[ "${python_home}" != "" ]]; then
  python=${python_home}
fi

echo "Python set ${python}"

CRYPTOKEY=`eval $PWCMD`
FERNETCRYPTOKEY=`${python} -c 'from cryptography.fernet import Fernet;key=Fernet.generate_key().decode();print key'`

sed -e "s|RABBITMQHOST|$RABBITMQ_HOST|" \
  -e "s|LOCALHOST|`hostname`|" \
  -e "s|DBCONNSTRING|$DBCONNSTRING|" \
  -e "s|temporary_key|$CRYPTOKEY|" \
  -e "s|cryptography_not_found_storing_passwords_in_plain_text|$FERNETCRYPTOKEY|" \
  -i ${airflow_home}/airflow.cfg
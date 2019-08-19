#!/bin/bash


# Creating the AIRFLOW_HOME directory
if [ ! -d ${airflow_home} ]; then
    mkdir -p ${airflow_home}
    chown -R airflow:airflow ${airflow_home}
fi

# Creating the Airflow log directory
if [ ! -d ${base_log_folder} ]; then
    mkdir -p ${base_log_folder}
    chown -R airflow:airflow ${base_log_folder}
fi

# Creating dags folder
if [ ! -d ${dags_folder} ]; then
    mkdir -p ${dags_folder}
    chown -R airflow:airflow ${dags_folder}
    chmod 775 ${dags_folder}
fi

# Initializing the Airflow database if not existed
if [ ! -f ${airflow_home}/airflow.cfg ]; then
    sudo -Eu airflow bash -c 'export PATH=${AIRFLOW_DIR}/usr/bin:$PATH;
    exec airflow initdb'
fi

# Building connection string
if [ "$dbType" == "mysql" ]; then
    sql_alchemy_conn="mysql://${dbUser}:${dbPass}@${dbHost}:${dbPort}/${dbName}"
elif [ "$dbType" == "postgresql" ]; then
    sql_alchemy_conn="postgresql+psycopg2://${dbUser}:${dbPass}@${dbHost}:${dbPort}/${dbName}"
fi

echo $sql_alchemy_conn
   
# Updating airflow.cfg

#broker_url="amqp://${RABBITMQ_USER}:${RABBITMQ_PASS}@${RABBITMQ_HOST}:${RABBITMQ_PORT}/"
celery_result_backend="db+${sql_alchemy_conn}"

PWCMD='< /dev/urandom tr -dc A-Za-z0-9 | head -c 20;echo'
secret_key=`eval $PWCMD`

function replace {
    sed -i "s#${1}#${2}#g" $3
}

function remove_line {
    sed -i "/${1}/d" $2
}

echo "Updating airflow.cfg..."
auth_backend_flag=false
auth_backend=airflow.contrib.auth.backends.password_auth

# Updating airflow.cfg
while read line; do
    key=$(cut -d "=" -f1 <<< "$line" | xargs)
    value=$(cut -d "=" -f2 <<< "$line")
    if [[ ${!key} ]]; then
        if [[ "$key" != "#" ]]; then
            if [[ "$key" == "authenticate" ]]; then
                replace "$key =${value}" "$key = ${!key}\nauth_backend = airflow.contrib.auth.backends.password_auth" ${airflow_home}/airflow.cfg
            elif [[ "$key" == "auth_backend" ]]; then
                if [[ "$auth_backend_flag" = true ]]; then
                    sed -i "/auth_backend = airflow.contrib.auth.backends.password_auth/d" ${airflow_home}/airflow.cfg
                fi
                auth_backend_flag=true
            else
                replace "$key =${value}" "$key = ${!key}" ${airflow_home}/airflow.cfg
            fi
        fi
    fi
done < ${airflow_home}/airflow.cfg


echo "Creating Airflow user..."
# Creating Airflow User

if [[ ! -z "$AIRFLOW_USER" ]];
then 
    ${AIRFLOW_DIR}/usr/bin/python2.7 ../scripts/mkuser.py $AIRFLOW_USER $AIRFLOW_EMAIL $AIRFLOW_PASS
fi


echo "Updating AIRFLOW_HOME in binaries..."
# Creating the airflow binary

sed -i "1s+.*+export AIRFLOW_HOME=${AIRFLOW_HOME}\n+" ${AIRFLOW_DIR}/bin/airflow.sh
chmod 777  ${AIRFLOW_DIR}/bin/airflow.sh

echo "export PYTHONPATH=${PYTHONPATH}" > /usr/bin/airflow-mkuser
echo "export PATH=${AIRFLOW_DIR}/bin:\$PATH" >> /usr/bin/airflow-mkuser
echo "${AIRFLOW_DIR}/bin/mkuser.sh \$@" >> /usr/bin/airflow-mkuser


echo "update.cfg script ends" 

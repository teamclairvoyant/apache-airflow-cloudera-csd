#!/bin/bash
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Copyright 2019 Clairvoyant, LLC.
#
set -x

# Time marker for both stderr and stdout
date 1>&2

# Running command
CMD=$1
OPTS=$2

# Printout with timestamp
function log {
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "$timestamp: $1"
}

function deploy_client_config {
  log "Converting airflow.properties to airflow.cfg ..."
  local DIR=$1
  local SECTION
  local KV
  local KEY
  local VAL
  while read -r line; do
    SECTION=$(echo "$line" | awk -F: '{print $1}')
    KV=$(echo "$line" | awk -F: '{print $2}')
    KEY=$(echo "$KV" | awk -F= '{print $1}')
    VAL=$(echo "$KV" | awk -F= '{print $2}')
    if [ -n "$KV" ]; then
      # Pythonize the boolean values.
      if [ "$VAL" == "true" ];  then VAL=True;  fi
      if [ "$VAL" == "false" ]; then VAL=False; fi
      crudini --set ${DIR}/airflow.cfg "$SECTION" "$KEY" "$VAL"
    else
      echo "- $SECTION"
      if [ -n "$SECTION" ]; then
        eval $SECTION
      fi
    fi
  done <${DIR}/airflow.properties

  # Building SQL connection string
  if [ "$DB_TYPE" == "SQLite3" ]; then
    VAL="sqlite:///${AIRFLOW_HOME}/airflow.db"
  elif [ "$DB_TYPE" == "MySQL" ]; then
    VAL="mysql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
  elif [ "$DB_TYPE" == "PostgreSQL" ]; then
    VAL="postgresql+psycopg2://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
  else
    unset VAL
    echo "ERROR: core:sql_alchemy_conn"
  fi
  if [ -n "$VAL" ]; then
    crudini --set ${DIR}/airflow.cfg "core" "sql_alchemy_conn" "$VAL"
    crudini --set ${DIR}/airflow.cfg "celery" "result_backend" "db+${VAL}"
  fi
  # Building Broker URL
  if [ "$CELERY_BROKER" == "RabbitMQ" ]; then
    VAL="amqp://${CELERY_BROKER_USER}:${CELERY_BROKER_PASS}@${CELERY_BROKER_HOST}:${CELERY_BROKER_PORT}/"
  elif [ "$CELERY_BROKER" == "Redis" ]; then
    VAL="redis://${CELERY_BROKER_USER}:${CELERY_BROKER_PASS}@${CELERY_BROKER_HOST}:${CELERY_BROKER_PORT}/"
  elif [ "$CELERY_BROKER" == "AmazonSQS" ]; then
    VAL="sqs://"
  else
    unset VAL
    echo "ERROR: celery:broker_url"
  fi
  if [ -n "$VAL" ]; then
    crudini --set ${DIR}/airflow.cfg "celery" "broker_url" "$VAL"
  fi

  # Append our AIRFLOW_HOME at the end to ensure that it's there
  echo -e "\nexport AIRFLOW_HOME=$AIRFLOW_HOME" >> ${DIR}/airflow-env.sh
}

function update_daemon_config {
  local DIR=$1
  export AIRFLOW_CONFIG=${DIR}/airflow.cfg
  log "AIRFLOW_CONFIG: $AIRFLOW_CONFIG"
  deploy_client_config ${DIR}

  # Append our AIRFLOW_CONFIG at the end to ensure that it's there
  echo -e "\nexport AIRFLOW_CONFIG=$AIRFLOW_CONFIG" >> ${DIR}/airflow-env.sh

  chgrp airflow ${DIR}/airflow.cfg ${DIR}/airflow-env.sh
}

log "*** AIRFLOW_HOME: $AIRFLOW_HOME"
log "*** AIRFLOW_CONFIG: $AIRFLOW_CONFIG"
log "*** PYTHONHOME: $PYTHONHOME"
log "*** PYTHONPATH: $PYTHONPATH"

case $CMD in

  client)
    deploy_client_config ${CONF_DIR}/airflow-conf
    log "Processing has finished successfully"
    exit 0
    ;;

  start_flower)
    update_daemon_config ${CONF_DIR}
    log "Starting Airflow flower..."
    su -s /bin/bash - airflow -c "CONF_DIR=$CONF_DIR exec airflow-cm.sh flower $OPTS"
    ;;

  start_kerberos)
    update_daemon_config ${CONF_DIR}
    log "Starting Airflow kerberos..."
    su -s /bin/bash - airflow -c "CONF_DIR=$CONF_DIR exec airflow-cm.sh kerberos $OPTS"
    ;;

  start_scheduler)
    update_daemon_config ${CONF_DIR}
    log "Starting Airflow scheduler..."
    su -s /bin/bash - airflow -c "CONF_DIR=$CONF_DIR exec airflow-cm.sh scheduler $OPTS"
    ;;

  start_webserver)
    update_daemon_config ${CONF_DIR}
    log "Starting Airflow webserver..."
    su -s /bin/bash - airflow -c "CONF_DIR=$CONF_DIR exec airflow-cm.sh webserver $OPTS"
    ;;

  start_worker)
    update_daemon_config ${CONF_DIR}
    log "Starting Airflow worker..."
    su -s /bin/bash - airflow -c "CONF_DIR=$CONF_DIR exec airflow-cm.sh worker $OPTS"
    ;;

  initdb)
    update_daemon_config ${CONF_DIR}
    log "Initializing the Airflow database..."
    su -s /bin/bash - airflow -c "CONF_DIR=$CONF_DIR exec airflow-cm.sh initdb"
    ;;

  upgradedb)
    update_daemon_config ${CONF_DIR}
    log "Upgrading the Airflow database..."
    su -s /bin/bash - airflow -c "CONF_DIR=$CONF_DIR exec airflow-cm.sh upgradedb"
    ;;

  *)
    log "Don't understand [$CMD]"
    ;;

esac


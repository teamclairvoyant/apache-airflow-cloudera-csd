#!/bin/bash

# Time marker for both stderr and stdout
date 1>&2

# Running command
CMD=$1

# Printout with timestamp
function log {
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "$timestamp: $1"
}

function deploy_client_config {
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
      crudini --set airflow.cfg "$SECTION" "$KEY" "$VAL"
    else
      echo "- $SECTION"
      if [ -n "$SECTION" ]; then
        eval $SECTION
      fi
    fi
  done <${CLIENT_CONF_DIR}/airflow.properties

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
    crudini --set airflow.cfg "core" "sql_alchemy_conn" "$VAL"
    crudini --set airflow.cfg "celery" "result_backend" "db+${VAL}"
  fi
  # Building Broker URL
  if [ "$CELERY_BROKER" == "RabbitMQ" ]; then
    VAL="amqp://${RABBITMQ_USER}:${RABBITMQ_PASS}@${RABBITMQ_HOST}:${RABBITMQ_PORT}/"
    #VAL="amqp://${CELERY_USER}:${CELERY_PASS}@${CELERY_HOST}:${CELERY_PORT}/"
  elif [ "$CELERY_BROKER" == "Redis" ]; then
    VAL="redis://${CELERY_USER}:${CELERY_PASS}@${CELERY_HOST}:${CELERY_PORT}/"
  elif [ "$CELERY_BROKER" == "Amazon SQS" ]; then
    VAL="sqs://"
  else
    unset VAL
    echo "ERROR: celery:broker_url"
  fi
  if [ -n "$VAL" ]; then
    crudini --set airflow.cfg "celery" "broker_url" "$VAL"
  fi
}

log "AIRFLOW_HOME: $AIRFLOW_HOME"
log "*** PYTHONPATH: $PYTHONPATH"

# TODO: remove?
CLIENT_CONF_DIR=${CONF_DIR}/airflow-conf

case $CMD in

  client)
    log "Converting airflow.properties to airflow.cfg ..."
    deploy_client_config

    # Append our AIRFLOW_HOME at the end to ensure that it's there
    echo -e "\nexport AIRFLOW_HOME=$AIRFLOW_HOME" >> ${CLIENT_CONF_DIR}/airflow-env.sh

    log "Processing has finished successfully"
    exit 0
    ;;

  *)
    log "Don't understand [$CMD]"
    ;;

esac


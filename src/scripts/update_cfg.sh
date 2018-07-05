#!/bin/bash

function replace {
    perl -pi -e "s#${1}#${2}#g" $3
}

dags_folder=testing
function prepare_airflow_cfg {
    counter=0
    while read line; do
        counter=$((counter+1))
        key=$(cut -d '=' -f1 <<< "$line" | xargs)
        value=$(cut -d '=' -f2 <<< "$line" | xargs)
        if [[ ${!key} ]]; then
            if [[ "$key" != "#" ]]; then
                echo "Key : ${key}, value : ${value}, keyvalue : ${!key}, linenumber : $counter" >> /tmp/test.txt
                replace "$key = ${value}" "$key = ${!key}" /tmp/airflow.cfg
            fi
        fi

    done < /tmp/airflow.cfg

}

prepare_airflow_cfg
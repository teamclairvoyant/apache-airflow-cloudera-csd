#!/bin/bash

function replace {
    # sed -i -e "s/${1}/${2}/g" $3
    perl -pi -e "s#${1}#${2}#g" $3
}

function prepare_airflow_cfg {
    echo $remote_base_log_folder >> /tmp/test2.txt
    while read line; do
        key=$(cut -d '=' -f1 <<< "$line" | xargs)
        value=$(cut -d '=' -f2 <<< "$line")
        echo "Key : '${key}', value : '${value}'" >> /tmp/test.txt
        if [[ ${!key} ]]; then
            if [[ "$key" != "#" ]]; then
                echo "'$key =${value}' '$key = ${!key}'" >> /tmp/test.txt
                replace "$key =${value}" "$key = ${!key}" ${airflow_home}/airflow.cfg
            fi
        fi

    done < ${airflow_home}/airflow.cfg

}

prepare_airflow_cfg
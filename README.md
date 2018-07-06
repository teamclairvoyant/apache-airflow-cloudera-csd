# Airflow CSD

## Requirements:
1. Python 2.7
2. Centos 6 or RedHatEnterpriseServer 6
3. Incase postgres is used: Postgres has to be installed and a database should be created for which the username and password has to be provided during the CSD installation.

## Structure of the service.sdl file
service.sdl file is used to manage all the configurations and commands for the services and roles in the CSD.

There are five roles defined in the CSD.
1. Airflow Webserver
2. Airflow Scheduler
3. Airflow Worker
4. RabbitMQ
5. Airflow Flower

Along with these five roles, a gateway has been defined for the purpose of writing configurations to the airflow.cfg

Each role has its own install script which will be run as a command before the role starts.

Airflow webserver, Worker and RabbitMQ services needs to be stopped using a stop script for each of the roles.

Gateway role: The purpose of the gateway role is to write the configurations from the configurations tab into the airflow.cfg file. This is done through the update_cfg.sh file which is executed from the scriptRunner within the gateway role.

Resources: 
1. https://github.com/cloudera/cm_ext/wiki/The-Structure-of-a-CSD
2. https://github.com/cloudera/cm_ext/wiki/Service-Descriptor-Language-Reference
3. https://github.com/cloudera/cm_csds
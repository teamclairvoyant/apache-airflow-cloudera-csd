# Airflow CSD

## Requirements:
1. Airflow and RabbitMQ parcels needs to be installed. Link to parcel repo: `https://github.com/teamclairvoyant/apache-airflow-parcels`
2. Centos 6 or RHEL 6 or Centos 7 or RHEL 7
3. A relational database needs to be installed.

## Installing the CSD
1. Download the Jar file from `http://apache-airflow.s3-website-us-east-1.amazonaws.com/cloudera/csd`
2. Copy the jar file to /opt/cloudera/csd location
3. Restart the cloudera server

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

## Manually triggering a DAG:
1. Navigate to Airflow parcel from the terminal.
2. Set the environment variables PTYHONPATH and AIRFLOW_HOME. By default, `PTYHONPATH` and `AIRFLOW_HOME` are:
	```
		export PYTHONPATH=/opt/cloudera/parcels/AIRFLOW-1.0.0-1.7.1.3-python2.7/usr/lib/python2.7/site-packages
		export AIRFLOW_HOME=/var/lib/airflow
	```
	Alternatively, you can also source the `envs.sh` file in `/opt/cloudera/parcels/AIRFLOW-1.0.0-1.7.1.3-python2.7/usr/bin`
3. Trigger the DAG using airflow binary from `/opt/cloudera/parcels/AIRFLOW-1.0.0-1.7.1.3-python2.7/usr/bin`.
	```
		./airflow trigger_dag <DAG>
	```

## Limitations:
1. Number of RabbitMQ instance is limited to 1. 
2. IP address of the RabbitMQ instance has to be manually entered during Installation configuration page.
3. After deploying configurations, no alert or warning that the specific roles needs to be restarted.
4. In the Configurations tab, the configurations cannot be filtered through specific roles. 
5. Only 'airflow.contrib.auth.backends.password_auth' mechanism is supported for Airflow user Authentication. 
6. Cannot look at all the existing Airflow users. All the previously added users needs to be tracked manually.

## Future work:
1. RabbitMQ needs to installed in Cluster Mode. 
2. Test Database connection
3. Build Airflow CSD and parcels for various versions. 
4. Automate the process of building parcels.
5. Add the support for more Airflow user Authentication method.

Resources: 
1. https://github.com/cloudera/cm_ext/wiki/The-Structure-of-a-CSD
2. https://github.com/cloudera/cm_ext/wiki/Service-Descriptor-Language-Reference
3. https://github.com/cloudera/cm_csds
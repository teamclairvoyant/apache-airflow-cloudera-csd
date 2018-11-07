# Airflow CSD

## Requirements:
- Airflow and RabbitMQ parcels needs to be installed. Link to parcel repo: `https://github.com/teamclairvoyant/apache-airflow-parcels`
- Centos 6 or RHEL 6 or Centos 7 or RHEL 7
- MySQL or PostgreSQL needs to be installed and setup inorder to store metadata. Here is some of the high level procedure to setup the database. 
   
   1. A database needs to be created.
   2. A database user needs to be created along with a password
   3. Grant all the privileges on the database to the newly created user. 
   
   Example for PostgreSQL:
   1. Create a Database.
      ```bash
      CREATE DATABASE <Database name>;
      ```
   2. Create a Database User
      ```bash
      CREATE USER <Database username> WITH ENCRYPTED PASSWORD '<Database Password>';
      ```
   3. Grant privileges for the user on the database.
      ```bash
      GRANT ALL PRIVILEGES ON DATABASE <Database name> to <Database username>;
      ```
   
## Installing the CSD
1. Download the Jar file from `http://teamclairvoyant.s3-website-us-west-2.amazonaws.com/apache-airflow/cloudera/csd/`
2. Copy the jar file to `/opt/cloudera/csd` location
3. Restart the cloudera server

## Structure of the service.sdl file
service.sdl file is used to manage all the configurations and commands for the services and roles in the CSD.

There are five roles defined in the CSD.
1. Airflow Webserver
2. Airflow Scheduler
3. Airflow Worker
4. RabbitMQ
5. Airflow Flower
6. Kerberos
7. Gateway

Airflow Webserver: Airflow Webserver role is used to start the Airflow Web UI. Webserver role can be deployed on more than instances. However, they will be the same and can be used for backup purposes.

Airflow Scheduler: Airflow Scheduler role is used to schedule the Airflow jobs. This is limited to one instance to reduce the risk of duplicate jobs. 

Airflow Worker: Airflow Worker role picks jobs from RabbitMQ and executed them on the nodes. Multiple instances can be deployed. 

RabbitMQ: RabbitMQ role facilitates the use of RabbitMQ as the messaging broker. Currently the number of roles is limited to 1.  

Airflow Flower: Airflow Flower is used to monitor  celery clusters. Multiple instances are supported

Kerberos: Kerberos is used to enable Kerberos protocol for the Airflow. It internally executes `airflow kerberos`. An external Kerberos Distribution Center must be setup. Multiple instances can be setup for load balancing purposes.

Gateway role: The purpose of the gateway role is to write the configurations from the configurations tab into the airflow.cfg file. This is done through the update_cfg.sh file which is executed from the scriptRunner within the gateway role.

## Using airflow binary: 
Here are some of the examples for airflow commands: 
#### Initializing airflow database: 
```bash
airflow initdb
```
#### Listing Airflow dags:
```bash
airflow list_dags
```
#### Manually triggering a DAG:
The dag file has to be copied to all the nodes to the dags folder manually. 
```bash
airflow trigger_dag <DAG Name>
```

For a complete list of airflow commands refer to `https://airflow.apache.org/cli.html`

## Deploying a dag:
  The DAG file has to be copied to `dags_folder` directory within all the nodes. It is important to manually distribute to all the nodes where the roles are deployed. 

## Enabling Authentication for Airflow Web UI:
   Inorder to enable authentication for Airflow Web UI check the "Enable Airflow Authentication" option. You can create Airflow users using one of two options below
    
#### Creating Airflow Users using UI:
1. Navigate to Airflow CSD. In the configurations page, enter the Airflow Username, Airflow Email, Airflow Password you want to create. 
2. Deploy the client configurations to create the Airflow user.

Note: Although the last created User shows up in the Airflow configurations, you can still use the previously created users

#### Using mkuser.sh 
Another way to add Airflow users is using the mkuser.sh file. Users can be added as follows:
1. Navigate to the current working directory of the CSD under `/var/run/cloudera-scm-agent/process`
2. Export PYTHONPATH and AIRFLOW_HOME environment variables. By Default these are 
PYTHONPATH:
```bash
        export PYTHONPATH=/opt/cloudera/parcels/AIRFLOW/usr/lib/python2.7/site-packages:$PYTHONPATH
```
Airflow Home: 
```bash
        export AIRFLOW_HOME=/var/lib/airflow
```
3. Within the scripts directory, you can find `mkuser.py` file. Execute `mkuser.py` to add Airflow user
```bash
        <PATH_TO_PYTHON_INTERPRETER> mkuser.py <Username> <User Email> <Password>
```
For example, this can be like 
```bash
       /opt/cloudera/parcels/AIRFLOW/usr/bin/python2.7 mkuser.py airflowUser airflow@email.com airflowUserPassword
```

## Limitations:
1. Number of RabbitMQ instance is limited to 1. 
2. IP address of the RabbitMQ instance has to be manually entered during Installation configuration page.
3. After deploying configurations, no alert or warning that the specific roles needs to be restarted. 
4. Only 'airflow.contrib.auth.backends.password_auth' mechanism is supported for Airflow user Authentication. 

## Future work:
1. RabbitMQ needs to installed in Cluster Mode. 
2. Test Database connection
3. Add the support for more Airflow user Authentication method.


## Known Errors:
### Markup already exists Error:

Upon many deployments, you may face an error called Markup file already exists while trying to stop a role and the process never stops. In that case, stop the process using "Abort" command. And navigate to `/var/run/cloudera-scm-agent/process` and delete all the `GracefulRoleStopRunner` directories.

### Lag in DAG Execution:

Occasionally, we experienced some delay in DAG execution. We are working to fix this. 

## Resources:
1. https://github.com/cloudera/cm_ext/wiki/The-Structure-of-a-CSD
2. https://github.com/cloudera/cm_ext/wiki/Service-Descriptor-Language-Reference
3. https://github.com/cloudera/cm_csds
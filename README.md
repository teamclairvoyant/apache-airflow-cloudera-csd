# Airflow Custom Service Descriptor ([CSD](https://github.com/cloudera/cm_ext/wiki/CSD-Overview#custom-service-descriptors))

This repository allows you to install [Apache Airflow](https://airflow.apache.org/) as a service managable by [Cloudera Manager](https://www.cloudera.com/products/product-components/cloudera-manager.html).

## Requirements
- A supported operating system.
- MySQL or PostgreSQL database in which to store Airflow metadata.
- RabbitMQ
- [Airflow Parcel](https://github.com/teamclairvoyant/apache-airflow-parcels)

### Currently Supported Versions of Airflow
- Airflow 1.9.0
- Airflow 1.10.0

### Currently Supported Operating Systems
- CentOS/RHEL 6 & 7
- Debian 8
- Ubuntu 14.04, 16.04, & 18.04

## Installing the CSD
1. Download the Jar file.  [Airflow CSD](http://archive.clairvoyantsoft.com/airflow/csd/)
2. Copy the jar file to the `/opt/cloudera/csd` location on the Cloudera Manager server.
3. Restart the Cloudera Manager Server service. `service cloudera-scm-server restart`

## Requirements
1. A database needs to be created.
2. A database user needs to be created along with a password.
3. Grant all the privileges on the database to the newly created user.
4. Set `AIRFLOWDB_PASSWORD` to a sufficient value. For example, run the following in your Linux shell session: `< /dev/urandom tr -dc A-Za-z0-9 | head -c 20;echo`

Example for MySQL:
1. Create a database.
   ```SQL
   CREATE DATABASE airflow DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
   ```
2. Create a new user and grant privileges on the database.
   ```SQL
   GRANT ALL ON airflow.* TO 'airflow'@'localhost' IDENTIFIED BY 'AIRFLOWDB_PASSWORD';
   GRANT ALL ON airflow.* TO 'airflow'@'%' IDENTIFIED BY 'AIRFLOWDB_PASSWORD';
   ```
Alternatively, you can use the [Airflow/MySQL deployment script](https://github.com/teamclairvoyant/hadoop-deployment-bash/blob/master/services/create_mysql_dbs-airflow.sh) to create the MySQL database using:
```bash
create_mysql_dbs-airflow.sh --host <host_name> --user <username> --password <password>
```

Example for PostgreSQL:
1. Create a role.
   ```SQL
   CREATE ROLE airflow LOGIN ENCRYPTED PASSWORD 'AIRFLOWDB_PASSWORD' NOSUPERUSER INHERIT CREATEDB NOCREATEROLE;
   ALTER ROLE airflow SET search_path = airflow, "$user", public;
   ```
2. Create a database.
   ```SQL
   CREATE DATABASE airflow WITH OWNER = airflow ENCODING = 'UTF8' TABLESPACE = pg_default CONNECTION LIMIT = -1;
   ```
Alternatively, you can use the [Airflow/PostgreSQL deployment script](https://github.com/teamclairvoyant/hadoop-deployment-bash/blob/master/services/create_postgresql_dbs-airflow.sh) to create the PostgreSQL database using:
```bash
create_postgresql_dbs-airflow.sh --host <host_name> --user <username> --password <password>
```

## Roles

There are six roles available for deployment:

1. Webserver
2. Scheduler
3. Worker
4. Flower Webserver
5. Kerberos
6. Gateway

Webserver: Airflow Webserver role runs the Airflow Web UI. Webserver role can be deployed on more than instances. However, they will be the same and can be used for backup purposes.

Scheduler: Airflow Scheduler role is used to schedule the Airflow jobs. This is limited to one instance to reduce the risk of duplicate jobs.

Worker: Airflow Worker role picks jobs from the Scheduler and executes them. Multiple instances can be deployed.

Flower Webserver: Flower Webserver role is used to monitor Celery clusters. Celery allows for the expansion of Worker  Only one instance is needed.

Kerberos: Airflow Kerberos role is used to enable Kerberos protocol for the other Airflow roles and for DAGs. This role should exist on each host with an Airflow Worker role.

Gateway: The purpose of the gateway role is to make the configuration available to CLI clients.

## Using the Airflow binary:
Here are some of the examples of Airflow commands:

### Listing Airflow DAGs:
```bash
airflow list_dags
```

### Manually triggering a DAG:
The dag file has to be copied to all the nodes to the dags folder manually.
```bash
airflow trigger_dag <DAG Name>
```

For a complete list of Airflow commands refer to the [Airflow Command Line Interface](https://airflow.apache.org/cli.html).

## Deploying a DAG:
The DAG file has to be copied to `dags_folder` directory within all the nodes. It is important to manually distribute to all the nodes where the roles are deployed.

## Enabling Authentication for Airflow Web UI:
In order to enable authentication for the Airflow Web UI check the "Enable Airflow Authentication" option. You can create Airflow users using one of two options below.

### Creating Airflow Users using UI:
One way to add Airflow users to the database is using the `airflow-mkuser` script.  Users can be added as follows:

1. Navigate to Airflow WebUI.
2. In the Admin dropdown choose Users.
3. Choose Create and enter the username, email, and password you want to create.

Note: Although the last created user shows up in the Airflow configurations, you can still use the previously created users.

### Using airflow-mkuser
Another way to add Airflow users to the database is using the `airflow-mkuser` script.  Users can be added as follows:

```bash
airflow-mkuser <username> <email> <password>
```
For example, this can be like:
```bash
airflow-mkuser admin admin@localdomain password123
```

## Building the CSD
```bash
git clone https://github.com/teamclairvoyant/apache-airflow-cloudera-csd
cd apache-airflow-cloudera-csd
make dist
```
Update the `version` file before running `make dist` if creating a new release.

## Limitations:
1. After deploying configurations, there is no alert or warning that the specific roles needs to be restarted.
2. Only 'airflow.contrib.auth.backends.password_auth' mechanism is supported for Airflow user authentication.

## Future work:
1. Build RabbitMQ parcel.
2. Test Database connection.
3. Add the support for more Airflow user authentication methods.

## Known Errors:

### Markup already exists Error:

Upon many deployments, you may face an error called 'Markup file already exists' while trying to stop a role and the process never stops. In that case, stop the process using the "Abort" command and navigate to `/var/run/cloudera-scm-agent/process` and delete all the `GracefulRoleStopRunner` directories.

## Resources:
1. https://github.com/teamclairvoyant/apache-airflow-parcels
2. https://github.com/cloudera/cm_ext/wiki/The-Structure-of-a-CSD
3. https://github.com/cloudera/cm_ext/wiki/Service-Descriptor-Language-Reference
4. https://github.com/cloudera/cm_csds


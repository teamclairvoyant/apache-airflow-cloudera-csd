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
# Copyright Clairvoyant 2016
#
if [ $DEBUG ]; then set -x; fi
if [ $DEBUG ]; then ECHO=echo; fi
#
##### START CONFIG ###################################################
#AIRFLOWUID="-u 999"
#AIRFLOWGID="-g 999"

MYSQL_PORT=3306
PGSQL_PORT=5432

AIRFLOW_VERSION=1.7.1.3
##### STOP CONFIG ####################################################
PATH=/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin
FILEPATH=`dirname $0`
#PIPOPTS="-q"
YUMOPTS="-y -e1 -d1"

# Function to print the help screen.
print_help () {
  echo "Usage:  $1 <args>"
  echo ""
  echo "          -t|--dbtype        <mysql|postgresql>"
  echo "          -d|--dbhost        <hostname>"
  echo "          [-P|--dbport       <port>]"
  echo "          -u|--dbuser        <username>"
  echo "          -p|--dbpassword    <password>"
  echo "          -r|--rabbitmqhost  <hostname>"
  echo "          [airflow version]"
  echo "          [-h|--help]"
  echo "          [-v|--version]"
  echo ""
  echo "   ex.  $1 --dbtype postgresql --dbhost hostA --dbuser airflow --dbpassword bar --rabbitmqhost hostB"
  exit 1
}

# Function to check for root priviledges.
check_root () {
  if [[ `/usr/bin/id | awk -F= '{print $2}' | awk -F"(" '{print $1}' 2>/dev/null` -ne 0 ]]; then
    echo "You must have root priviledges to run this program."
    exit 2
  fi
}

# Function to print and error message and exit.
err_msg () {
  local CODE=$1
  echo "ERROR: Could not install required package. Exiting."
  exit $CODE
}

# Function to discover basic OS details.
discover_os () {
  if command -v lsb_release >/dev/null; then
    # CentOS, Ubuntu
    OS=`lsb_release -is`
    # 7.2.1511, 14.04
    OSVER=`lsb_release -rs`
    # 7, 14
    OSREL=`echo $OSVER | awk -F. '{print $1}'`
    # trusty, wheezy, Final
    OSNAME=`lsb_release -cs`
  else
    if [ -f /etc/redhat-release ]; then
      if [ -f /etc/centos-release ]; then
        OS=CentOS
      else
        OS=RedHatEnterpriseServer
      fi
      OSVER=`rpm -qf /etc/redhat-release --qf="%{VERSION}.%{RELEASE}\n"`
      OSREL=`rpm -qf /etc/redhat-release --qf="%{VERSION}\n" | awk -F. '{print $1}'`
    fi
  fi
}

# Process arguments.
while [[ $1 = -* ]]; do
  case $1 in
    -t|--dbtype)
      shift
      DB_TYPE=$1
      ;;
    -d|--dbhost)
      shift
      DB_HOST=$1
      ;;
    -r|--rabbitmqhost)
      shift
      RABBITMQ_HOST=$1
      ;;
    -u|--dbuser)
      shift
      DB_USER=$1
      ;;
    -p|--dbpassword)
      shift
      DB_PASSWORD=$1
      ;;
    -P|--dbport)
      shift
      DB_PORT=$1
      ;;
    -h|--help)
      print_help "$(basename $0)"
      ;;
    -v|--version)
      echo "Install Airflow."
      exit 0
      ;;
    *)
      print_help "$(basename $0)"
      ;;
  esac
  shift
done

echo "********************************************************************************"
echo "*** $(basename $0)"
echo "********************************************************************************"
# Check to see if we are on a supported OS.
# Currently only EL7.
discover_os
if [ \( "$OS" != RedHatEnterpriseServer -o "$OS" != CentOS \) -a \( "$OSREL" != 6 -a "$OSREL" != 7 \) ]; then
#if [ "$OS" != RedHatEnterpriseServer -a "$OS" != CentOS -a "$OS" != Debian -a "$OS" != Ubuntu ]; then
  echo "ERROR: Unsupported OS."
  exit 3
fi

if [[ "$OSREL" != 6 ]]; then
  echo "error"
fi

# Check to see if we have the required parameters.
if [ -z "$DB_TYPE" -o -z "$DB_HOST" -o -z "$DB_USER" -o -z "$DB_PASSWORD" -o -z "$RABBITMQ_HOST" ]; then print_help "$(basename $0)"; fi
if [ "$DB_TYPE" != "mysql" -a "$DB_TYPE" != "postgresql" ]; then
  echo "** ERROR: --dbtype must be one of mysql or postgresql."
  echo ""
  print_help "$(basename $0)"
fi

# Lets not bother continuing unless we have the privs to do something.
#check_root

# main
echo "Installing Airflow..."
if [ -n "$1" ]; then
  VERSION="==$1"
fi

if ! getent group airflow >/dev/null; then
  echo "** Installing airflow group."
  groupadd $AIRFLOWGID -r airflow
fi
if ! getent passwd airflow >/dev/null; then
  echo "** Installing airflow user."
  useradd $AIRFLOWUID -g airflow -c "Airflow Daemon" -m -d ${airflow_home} -k /dev/null -r airflow
fi

if [ "$OS" == RedHatEnterpriseServer -o "$OS" == CentOS ]; then

  chown airflow:airflow ${airflow_home}/airflow.cfg 
  echo "** Installing software dependencies via YUM."
  yum $YUMOPTS groupinstall "Development tools"
  yum $YUMOPTS install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel python-devel wget cyrus-sasl-devel.x86_64

  echo "** Installing Airflow."
  pip=pip
  if [[ "${pip_home}" != "" ]]; then
    pip=${pip_home}
  fi
  echo "Using pip ${pip}"
  ${pip} $PIPOPTS install airflow==$AIRFLOW_VERSION
  # Fix a bug in celery 4
  ${pip} $PIPOPTS install 'celery<4'
  ${pip} $PIPOPTS install airflow[celery]

  if [ "$DB_TYPE" == "mysql" ]; then
    if [ -z "$DB_PORT" ]; then DB_PORT=$MYSQL_PORT; fi
    #####
    echo "** Installing Airflow[mysql]."
    yum $YUMOPTS install mysql-devel
    ${pip} $PIPOPTS install airflow[mysql]

  elif [ "$DB_TYPE" == "postgresql" ]; then
    if [ -z "$DB_PORT" ]; then DB_PORT=$PGSQL_PORT; fi
    #####
    echo "** Installing Airflow[postgres]."
    yum $YUMOPTS install postgresql-devel
    ${pip} $PIPOPTS install airflow[postgres]
  fi

  yum $YUMOPTS install rabbitmq-server 
  
  echo "** Installing Airflow[kerberos]."
  ${pip} $PIPOPTS install airflow[kerberos]==$AIRFLOW_VERSION
  yum $YUMOPTS install libffi-devel
  echo "** Installing Airflow[crypto]."
  ${pip} $PIPOPTS install airflow[crypto]==$AIRFLOW_VERSION
  #pip $PIPOPTS install airflow[jdbc]
  echo "** Installing Airflow[hive]."
  ${pip} $PIPOPTS install airflow[hive]==$AIRFLOW_VERSION
  #pip $PIPOPTS install airflow[hdfs]
  #pip $PIPOPTS install airflow[ldap]
  ${pip} $PIPOPTS install airflow[password]==$AIRFLOW_VERSION
  echo "** Installing Airflow[rabbitmq]."
  ${pip} $PIPOPTS install airflow[rabbitmq]==$AIRFLOW_VERSION
  #pip $PIPOPTS install airflow[s3]

  echo "** Installing Airflow configs."
  install -o airflow -g airflow -m0750 -d ${airflow_home}
  install -o airflow -g airflow -m0750 -d ${airflow_home}/plugins
  install -o airflow -g airflow -m0750 -d ${airflow_home}/dags
  install -o airflow -g airflow -m0750 -d /var/log/airflow
  install -o airflow -g airflow -m0644 ${FILEPATH}/airflow/unittests.cfg ${airflow_home}/
  install -o airflow -g airflow -m0644 ${FILEPATH}/airflow/airflow.logrotate /etc/logrotate.d/

  echo "** Initializing Airflow database."
  su airflow -c 'airflow initdb'


elif [ "$OS" == Debian -o "$OS" == Ubuntu ]; then
  :
fi


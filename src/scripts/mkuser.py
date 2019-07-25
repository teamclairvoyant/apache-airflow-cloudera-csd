#!/usr/bin/python
# https://airflow.incubator.apache.org/security.html

import sys, logging, argparse

from airflow import models, settings
from airflow.contrib.auth.backends.password_auth import PasswordUser

username = sys.argv[1]
email = sys.argv[2]
password = sys.argv[3]

session = settings.Session()

#add any needed parameters if necessary
parser=argparse.ArgumentParser(
    description='''Create users with airflow create_user. ''',
    epilog="""Please refer apache-airflow for more args!.""")
parser.add_argument('-r', type=int, default=42, help='ROLE!')
parser.add_argument('-u', type=int, default=42, help='USERNAME!')
parser.add_argument('-e', type=int, default=42, help='EMAIL!')
parser.add_argument('-f', type=int, default=42, help='FIRSTNAME!')
parser.add_argument('-l', type=int, default=42, help='LASTNAME!')
parser.add_argument('-p', type=int, default=42, help='PASSWORD!')
args=parser.parse_args()

def is_user_exists(username):
    return (session.query(models.User).filter(models.User.username == username).first() != None)

if (not is_user_exists(username)):
    user = PasswordUser(models.User())
    logging.info("Adding Airflow user "+username+"...")
    user.username = username
    user.email = email
    user._set_password = password
    session.add(user)
    session.commit()
    logging.info("Successfully added Airflow user.")
    session.close()
else:
    logging.warning("Airflow User "+username+" already exists")


exit()

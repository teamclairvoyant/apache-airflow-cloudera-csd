#!/usr/bin/python
# https://airflow.incubator.apache.org/security.html

import sys, logging

from airflow import models, settings
from airflow.contrib.auth.backends.password_auth import PasswordUser

username = sys.argv[1]
email = sys.argv[2]
password = sys.argv[3]

session = settings.Session()

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
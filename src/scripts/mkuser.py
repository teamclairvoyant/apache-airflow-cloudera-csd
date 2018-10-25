#!/usr/bin/python
# https://airflow.incubator.apache.org/security.html

import sys

import airflow
from airflow import models, settings
from airflow.contrib.auth.backends.password_auth import PasswordUser

import string
from random import sample, choice

username = sys.argv[1]
email = sys.argv[2]
password = sys.argv[3]

session = settings.Session()

def is_user_exists(username):
	return (session.query(models.User).filter(models.User.username == username).first() != None)

if is_user_exists(!username):
	user = PasswordUser(models.User())
	user.username = username
	user.email = email
	user._set_password = password
	session.add(user)
	session.commit()
	session.close()

exit()

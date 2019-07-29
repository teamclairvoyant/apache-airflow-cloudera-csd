#!/bin/bash -x
for pid in `ps -ef | grep "flower" | awk '{print $2}'` ; do kill -s KILL $pid || true ; done

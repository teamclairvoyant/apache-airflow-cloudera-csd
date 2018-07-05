for pid in `ps -ef | grep "rabbit" | awk '{print $2}'` ; do kill -9 $pid ; done

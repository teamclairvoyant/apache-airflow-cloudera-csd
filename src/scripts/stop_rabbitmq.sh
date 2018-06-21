for pid in `ps -ef | grep "rabbitmq" | awk '{print $2}'` ; do kill -9 $pid ; done

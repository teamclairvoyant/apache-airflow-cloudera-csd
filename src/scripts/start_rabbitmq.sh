export PATH=${RABBITMQ_DIR}/usr/lib64/erlang/bin:$PATH
exec ${RABBITMQ_DIR}/usr/lib/rabbitmq/bin/rabbitmq-server start

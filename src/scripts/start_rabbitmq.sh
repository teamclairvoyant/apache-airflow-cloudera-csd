export PATH=${RABBITMQ_DIR}/usr/lib64/erlang/erts-10.1/bin:$PATH
exec ${RABBITMQ_DIR}/usr/lib/rabbitmq/bin/rabbitmq-server start

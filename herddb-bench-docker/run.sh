#!/bin/bash

# -------------- #
set -x -e -u
# -------------- #

# -------------- #
# Allow the container to be started with `--user`
if [ "$1" = 'bookkeeper' -a "$(id -u)" = '0' ]; then
    chown -R "$HERD_USER" "${HERD_DIR}" "${HERD_DATA_DIR}"
    exec su-exec "$HERD_USER" /bin/bash "$0" "$@"
    exit
fi
# -------------- #

# -------------- #
# Copy input config files in Bookkeeper configuration directory
cp -vaf /conf/* ${HERD_DIR}/conf || true
chown -R "$HERD_USER" ${HERD_DIR}/conf

# Herd setup: server.properties
sed -r -i.bak \
	-e "s|^server.baseDir.*=.*|server.baseDir=${HERD_DATA_DIR}|" \
	-e "s|^server.users.file.*=.*|server.users.file=${HERD_DIR}/conf/users|" \
	${HERD_DIR}/conf/server.properties

if [[ "${ZK_SERVERS}" != "" ]]; then
	sed -r -i "s|^server.zookeeper.address.*=.*|server.zookeeper.address=${ZK_SERVERS}|" ${HERD_DIR}/conf/server.properties
fi
if [[ "${HERD_HOST}" != "" ]]; then
	sed -r -i "s|^server.host.*=.*|server.host=${HERD_HOST}|" ${HERD_DIR}/conf/server.properties
fi
if [[ "${HERD_PORT}" != "" ]]; then
	sed -r -i "s|^server.port.*=.*|server.port=${HERD_PORT}|" ${HERD_DIR}/conf/server.properties
fi
if [[ "${HERD_MODE}" != "" ]]; then
	sed -r -i "s|^server.mode.*=.*|server.mode=${HERD_MODE}|" ${HERD_DIR}/conf/server.properties
fi
if [[ "${HERD_NODE_ID}" != "" ]]; then
	sed -r -i "s|^server.nodeId.*=.*|server.nodeId=${HERD_NODE_ID}|" ${HERD_DIR}/conf/server.properties
fi
if [[ "${HERD_PORT}" != "" ]]; then
	sed -r -i "s|^server.port.*=.*|server.port=${HERD_PORT}|" ${HERD_DIR}/conf/server.properties
fi
if [[ "${HERD_SSL}" != "" ]]; then
	sed -r -i "s|^server.ssl.*=.*|server.ssl=${HERD_SSL}|" ${HERD_DIR}/conf/server.properties
fi
if [[ "${BK_START}" != "" ]]; then
	sed -r -i "s|^server.bookkeeper.start.*=.*|server.bookkeeper.start=${BK_START}|" ${HERD_DIR}/conf/server.properties
fi
if [[ "${BK_PORT}" != "" ]]; then
	sed -r -i "s|^server.bookkeeper.port.*=.*|server.bookkeeper.port=${BK_PORT}|" ${HERD_DIR}/conf/server.properties
fi
if [[ "${BK_ENSAMBLE_SIZE}" != "" ]]; then
	sed -r -i "s|^server.bookkeeper.ensemblesize.*=.*|server.bookkeeper.ensemblesize=${BK_ENSAMBLE_SIZE}|" ${HERD_DIR}/conf/server.properties
fi
if [[ "${BK_WRITE_QUORUM_SIZE}" != "" ]]; then
	sed -r -i "s|^server.bookkeeper.writequorumsize.*=.*|server.bookkeeper.writequorumsize=${BK_WRITE_QUORUM_SIZE}|" ${HERD_DIR}/conf/server.properties
fi
if [[ "${BK_ACKQUORUM_SIZE}" != "" ]]; then
	sed -r -i "s|^server.bookkeeper.ackquorumsize.*=.*|server.bookkeeper.ackquorumsize=${BK_ACKQUORUM_SIZE}|" ${HERD_DIR}/conf/server.properties
fi

diff ${HERD_DIR}/conf/server.properties.bak ${HERD_DIR}/conf/server.properties || true

# Herd setup: setenv.sh
if [[ "${HERD_MEMORY}" != "" ]]; then
        sed -r -i.bak \
                -e "s|\-Xmx[^ ]+|-Xmx${HERD_MEMORY}|g" \
                -e "s|\-Xms[^ ]+|-Xms${HERD_MEMORY}|g" \
            ${HERD_DIR}/bin/setenv.sh
fi

diff ${HERD_DIR}/bin/setenv.sh.bak ${HERD_DIR}/bin/setenv.sh || true

# Herd setup: logging
if [[ "${BK_LOGGING_LEVEL}" != "" ]]; then
        sed -r -i.bak \
                -e "s|org\.apache\.bookkeeper\.level.*=.*|org.apache.bookkeeper.level=${BK_LOGGING_LEVEL}|g" \
            ${HERD_DIR}/conf/logging.properties
fi

diff ${HERD_DIR}/conf/logging.properties ${HERD_DIR}/conf/logging.properties || true
# -------------- #

# -------------- #
if [[ "${PURGE_DATA_AT_START}" == "true" ]]; then
    rm -rf /data/*
fi
# -------------- #


# -------------- #
# Run command
if [[ "$@" == "service server start" ]]; then
    touch ${HERD_DIR}/server.service.log
    exec "$@" -Dherddb.network.disablenativeepoll=true &
    tail -f ${HERD_DIR}/server.service.log
else
    exec "$@"
fi
# -------------- #

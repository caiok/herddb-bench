FROM java:openjdk-8-jre-alpine
MAINTAINER Francesco Caliumi <francesco.caliumi@gmail.com>

# Install required packages
RUN apk add --no-cache \
    bash \
    su-exec

ENV HERD_USER=herddb \
    HERD_MEMORY= \
    HERD_HOST= \
    HERD_PORT= \
    HERD_BUILD_PORT=7000 \
    HERD_DIR=/opt/herddb \
    HERD_DATA_DIR=/data/ \
    HERD_MODE= \
    HERD_NODE_ID= \
    HERD_SSL=false \
    ZK_SERVERS= \
    BK_START=true \
    BK_PORT=0 \
    BK_ENSAMBLE_SIZE=1 \
    BK_WRITE_QUORUM_SIZE=1 \
    BK_ACKQUORUM_SIZE=1 \
    BK_LOGGING_LEVEL= \
    PURGE_DATA_AT_START=false

# Add a user and make dirs
RUN set -x \
    && adduser -D "${HERD_USER}" \
    && mkdir -p "${HERD_DATA_DIR}" \
    && chown "$HERD_USER:$HERD_USER" "${HERD_DATA_DIR}"

#ARG GPG_KEY=D0BC8D8A4E90A40AFDFC43B3E22A746A68E327C1
#ARG HERD_VERSION=4.4.0

ENV DISTRO_NAME=bookkeeper-server-${HERD_VERSION}-bin
	
# Download Herddb, verify its PGP signature, untar and clean up
#RUN set -x \
#    && apk add --no-cache --virtual .build-deps \
#        gnupg \
#        wget \
#    && mkdir -pv /opt \
#    && cd /opt \
#    && wget -q "https://archive.apache.org/dist/bookkeeper/bookkeeper-${HERD_VERSION}/${DISTRO_NAME}.tar.gz" \
#    && wget -q "https://archive.apache.org/dist/bookkeeper/bookkeeper-${HERD_VERSION}/${DISTRO_NAME}.tar.gz.asc" \
#    && export GNUPGHOME="$(mktemp -d)" \
#    && gpg --keyserver ha.pool.sks-keyservers.net --recv-key "$GPG_KEY" \
#    && gpg --batch --verify "$DISTRO_NAME.tar.gz.asc" "$DISTRO_NAME.tar.gz" \
#    && tar -xzf "$DISTRO_NAME.tar.gz" \
#    && rm -r "$GNUPGHOME" "$DISTRO_NAME.tar.gz" "$DISTRO_NAME.tar.gz.asc" \
#    && apk del .build-deps

# Copy and unzip Herd
COPY build/herddb-services-*.zip /opt/
RUN set -x \
    && apk add --no-cache --virtual .build-deps \
        unzip \
    && cd /opt \
    && unzip herddb-services-*.zip \
    && rm -fv herddb-services-*.zip \
    && mv herddb-services-* ${HERD_DIR} \
    && apk del .build-deps

#ENV HERD_DIR=/opt/bookkeeper-server-${HERD_VERSION}
ENV PATH=$PATH:${HERD_DIR}/bin

WORKDIR ${HERD_DIR}
VOLUME ["/conf", "${HERD_DATA_DIR}"]

EXPOSE ${HERD_BUILD_PORT}/tcp

COPY run.sh healthcheck.sh /local/

ENTRYPOINT [ "/bin/bash", "/local/run.sh" ]
CMD ["service", "server", "start"]

HEALTHCHECK --interval=3s --timeout=60s CMD /bin/bash /local/healthcheck.sh

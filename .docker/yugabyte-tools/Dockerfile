FROM alpine:3.14

ARG GID=1060
ARG GROUPNAME=yugabyte
ARG UID=1060
ARG USERNAME=yugabyte

RUN addgroup -g ${GID} ${GROUPNAME} \
    && adduser -u ${UID} -G ${GROUPNAME} -D -H ${USERNAME}
COPY --chown=${USERNAME}:${GROUPNAME} tools /home/${USERNAME}
RUN mkdir -p /home/${USERNAME}/www \
    && chown ${USERNAME}:${GROUPNAME} /home/${USERNAME}/www \
    && ln -s /home/${USERNAME}/bin/cqlsh /usr/bin/cqlsh \
    && ln -s /home/${USERNAME}/bin/yb-admin /usr/bin/yb-admin \
    && ln -s /home/${USERNAME}/bin/yb-bulk_load /usr/bin/yb-bulk_load \
    && ln -s /home/${USERNAME}/bin/yb-ctl /usr/bin/yb-ctl \
    && ln -s /home/${USERNAME}/bin/yb-ts-cli /usr/bin/yb-ts-cli \
    && ln -s /home/${USERNAME}/bin/ysql_bench /usr/bin/ysql_bench \
    && ln -s /home/${USERNAME}/bin/ysql_dump /usr/bin/ysql_dump \
    && ln -s /home/${USERNAME}/bin/ysql_dumpall /usr/bin/ysql_dumpall \
    && ln -s /home/${USERNAME}/bin/ysqlsh /usr/bin/ysqlsh

USER ${USERNAME}

FROM centos:7.9.2009 as builder
ARG YB_VERSION=2.9.1.0

RUN yum update -y && yum install -y wget curl \
    && wget https://downloads.yugabyte.com/yugabyte-${YB_VERSION}-linux.tar.gz -O /yugabyte-${YB_VERSION}-linux.tar.gz

FROM centos:7.9.2009
ARG GID=1060
ARG GROUPNAME=yugabyte
ARG UID=1060
ARG USERNAME=yugabyte
ARG YB_VERSION=2.9.1.0

RUN groupadd -g ${GID} ${GROUPNAME} \
    && useradd -m -d /home/${USERNAME} -g ${GID} -u ${UID} -s /bin/bash ${USERNAME}

COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY --from=builder /yugabyte-${YB_VERSION}-linux.tar.gz /home/${USERNAME}/yugabyte-${YB_VERSION}-linux.tar.gz

RUN chmod +x /docker-entrypoint.sh \
    && tar xvfz /home/${USERNAME}/yugabyte-${YB_VERSION}-linux.tar.gz -C /home/${USERNAME} --strip 1 \
    && rm -rf /home/${USERNAME}/yugabyte-${YB_VERSION}-linux.tar.gz \
    && /home/${USERNAME}/bin/post_install.sh \
    && chown -R ${USERNAME}:${GROUPNAME} /home/${USERNAME} \
    && ln -s /home/${USERNAME}/bin/yb-admin /usr/local/bin/yb-admin \
    && ln -s /home/${USERNAME}/bin/yb-ts-cli /usr/local/bin/yb-ts-cli \
    && ln -s /home/${USERNAME}/bin/ycqlsh /usr/local/bin/ycqlsh \
    && ln -s /home/${USERNAME}/bin/ysqlsh /usr/local/bin/ysqlsh \
    && ln -s /home/${USERNAME}/bin/yugabyted /usr/local/bin/yugabyted \
    && chown -R ${USERNAME}:${GROUPNAME} /usr/local/bin \
    && mkdir -p /mnt/{master,tserver} \
    && chown -R ${USERNAME}:${GROUPNAME} /mnt

USER ${USERNAME}

ENTRYPOINT ["/docker-entrypoint.sh"]
FROM debian:jessie

RUN \
  apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6 \
  && echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/3.4 main" > /etc/apt/sources.list.d/mongodb-org-3.4.list \
  && apt-get update \
  && apt-get install -y \
      coreutils \
      curl \
      duply \
      gettext-base \
      gnupg \
      mailutils \
      mongodb-org-tools \
      openssh-client \
      pwgen \
      python-boto \
      rsync \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /root/.duply/project
COPY config/conf.template /root/.duply/project/conf.template
WORKDIR /root/.duply/project

VOLUME /to_backup
VOLUME /tmp

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD []

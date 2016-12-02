FROM debian:jessie

RUN \
  apt-get update \
  && apt-get install -y \
      duply \
      openssh-client \
      pwgen \
      rsync \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

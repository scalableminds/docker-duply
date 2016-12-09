# docker-duply

[![CircleCI Status](https://circleci.com/gh/scalableminds/docker-duply.svg?&style=shield)](https://circleci.com/gh/scalableminds/docker-duply)

A dockerized duply for backups.

# Usage

```
docker run \
  -v "...:/to_backup" \
  -v "...:/tmp" \
  -e "GPG_PW=..." \
  -e "SCHEME=..." \
  -e "HOST=..." \
  -e "HOSTPATH=..." \
  -e "USER=..." \
  -e "PASSWORD=..." \
  -e "MAIL_FOR_ERRORS=..." \
  --rm \
  scalableminds/duply:branch-master
```

# Builds

The Docker images are built by [CircleCI](https://circleci.com/gh/scalableminds/docker-duply).

# License

[MIT 2016 scalable minds](LICENSE.txt)

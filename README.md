# Story_ API

PostgreSQL backend and Golang [echo](https://echo.labstack.com) server for story_.

## Prerequisites
- docker-ce ([Linux](https://docs.docker.com/install/#server), [MacOS](https://docs.docker.com/docker-for-mac/install/), [Windows 10 Pro/Enterprise](https://docs.docker.com/docker-for-windows/install/), [Windows 10 Home](https://download.docker.com/win/stable/DockerToolbox.exe))
- docker-compose ([Linux](https://docs.docker.com/compose/install/#linux), MacOS: included with docker-ce, Windows: included with docker-ce)
- go
- [dep](https://github.com/golang/dep)
- git
- make
- openssl

### Generate keys, pull docker images, and install Go packages.
```bash
$ make init
```

# Setup (environment, docker containers)
First, source the setup script. This script exports necessary environment variables and starts the `postgres` docker container for the selected environment.
**NOTE: an `'address already in use'` error will probably occur if a local postgres client is already running**
```bash
$ source setup.sh
```
# Local Development
Starting the server, Dropping/Removing containers, Creating tables, inserting test data, dropping tables, etc. is all handled via the interactive script `run.sh`.
```bash
$ ./run.sh
```

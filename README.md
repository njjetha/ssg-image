# ssg-image
Docker image for building the securemsm modules

This repository contains Docker image containing necessary tools
for building securemsm modules,as well as a few handy shell aliases 
for invoking operations within the Docker environment.

## Installing docker

If Docker isn't installed on your system yet, you can follow the instructions
provided at Docker's official documentation.

https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository

### Add user to the docker group
```
sudo adduser $(whoami) docker
newgrp docker
```

Restart your terminal, or log out and log in again, to ensure your user is
added to the **docker** group (the output of `id` should contain *docker*).

# TL;DR (Step-by-Step)

The following example captures how to setup a docker continer to build securemsm modules.

### 1. Clone kmake-image
```
git clone git@https://github.com/qualcomm/ssg-image.git
cd ssg-image
```
Build docker
```
docker build -t ssg-image .
```
or
```
docker build --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) --build-arg USER_NAME=$(whoami) -t ssg-image .
```

### 2. Setup the aliases in your .bashrc
```
alias ssg-image-run='docker run -it --rm --user $(id -u):$(id -g) --workdir="$PWD" -v "$(dirname $PWD)":"$(dirname $PWD)" ssg-image'

```

# TL;DR (Quick Start)

## Workspace Setup Script
*setup.sh* script simplify the initial docker,builds container and setup for securemsm developers:
- Builds the Docker image.
- Export necessary environment variables for securemsm development.
```
./setup.sh
```
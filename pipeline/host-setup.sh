#!/bin/bash
# 
# host-setup.sh
#
# This script will setup an Ubuntu host to act as a Dockerized build environment. This
# script requires sudo access and depends on apt-get to install required libraries.
# This script can be run from anywhere in the file system. It will default to creating
# all necessary directories under /apps/build with all applications storing data in
# subdirectories under that directory.
#
# Currently, all containers are configured to mount volumes on directories on the host's
# file system. Eventually, I should change this to data volumes. I just need to wrap my
# head around how to backup those data-only containers.

echo "********* Starting build environment Docker host setup script *********"

# All environment data will be stored underneath this directory
BASE_DIR="/apps/build"

JENKINS_DIR=$BASE_DIR/jenkins
SONARQUBE_DIR=$BASE_DIR/sonarqube
SONARQUBE_CONF_DIR=$SONARQUBE_DIR/conf
SONARQUBE_DATA_DIR=$SONARQUBE_DIR/data
SONARQUBE_PLUGINS_DIR=$SONARQUBE_DIR/plugins
SONARQUBE_EXTENSIONS_DIR=$SONARQUBE_DIR/extensions
MYSQL_DIR=$BASE_DIR/mysql/data
NEXUS_DIR=$BASE_DIR/nexus
DOCKER_REGISTRY_DIR=$BASE_DIR/docker/registry
REPO_DIR=$BASE_DIR/repo
WORK_DIR=$REPO_DIR/infrastructure/build

echo "********* Installing Docker *********"

# Install Docker
sudo apt-get update
sudo apt-get remove docker docker-engine
sudo apt-get install \
        linux-image-extra-$(uname -r) \
        linux-image-extra-virtual
sudo apt-get install \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install docker-ce

# Test that Docker installed correctly
sudo docker run hello-world

# Install Docker Compose
sudo apt-get install docker-compose

echo "********* Installing git & vim *********"

# Install git
sudo apt-get install git

# Install vim
sudo apt-get install vim

# Create directory to house code repository
mkdir -p $REPO_DIR

echo "********* Cloning infrastructure repository *********"
# Clone into git infrastructure repository
git clone https://github.com/jasonandersen/infrastructure.git $REPO_DIR

echo "********* Building directories to house data from containers *********"
# Create directories for all the build applications to house data on the host system.
mkdir -pv $JENKINS_DIR
mkdir -pv $SONARQUBE_CONF_DIR 
mkdir -pv $SONARQUBE_DATA_DIR
mkdir -pv $SONARQUBE_EXTENSIONS_DIR
mkdir -pv $SONARQUBE_PLUGINS_DIR
mkdir -pv $MYSQL_DIR
mkdir -pv $NEXUS_DIR
mkdir -pv $DOCKER_REGISTRY_DIR

# Nexus requires UID 200 to own the Nexus working directory
sudo chown 200 $NEXUS_DIR

echo "********* Creating Docker Compose environment file *********"
# Create .env file specifically for this host
touch $WORK_DIR/auto.env
echo "HOST_CODE_PATH=$REPO_DIR" >> $WORK_DIR/auto.env
echo "HOST_MYSQL_DATA=$MYSQL_DIR" >> $WORK_DIR/auto.env
echo "HOST_JENKINS_HOME=$JENKINS_DIR" >> $WORK_DIR/auto.env
echo "HOST_SONAR_DATA=$SONARQUBE_DATA_DIR" >> $WORK_DIR/auto.env
echo "HOST_SONAR_CONF=$SONARQUBE_CONF_DIR" >> $WORK_DIR/auto.env
echo "HOST_SONAR_EXTENSIONS=$SONARQUBE_EXTENSIONS_DIR" >> $WORK_DIR/auto.env
echo "HOST_SONAR_PLUGINS=$SONARQUBE_PLUGINS_DIR" >> $WORK_DIR/auto.env
echo "HOST_NEXUS_DATA=$NEXUS_DIR" >> $WORK_DIR/auto.env
echo "HOST_DOCKER_REGISTRY=$DOCKER_REGISTRY_DIR" >> $WORK_DIR/auto.env
echo "MYSQL_ROOT_PASSWORD=" >> $WORK_DIR/auto.env
echo "SONARQUBE_JDBC_USERNAME=" >> $WORK_DIR/auto.env
echo "SONARQUBE_JDBC_PASSWORD=" >> $WORK_DIR/auto.env


# Run script to build Docker containers 
sudo ./buildimgs.sh

echo "********* Booting up the build environment *********"
# Run Docker Compose to stand up environment
sudo docker-compose up -d

#! /bin/sh

##
## This script manages the Docker PSQL Container
##
## Usage: ./psql_docker.sh start|stop|create [db_username][db_password]
##
## Examples:
##  ./scripts/psql_docker.sh create db_username db_password
##  ./scripts/psql_docker.sh start
##  ./scripts/psql_docker.sh stop
##


# Capture CLI arguments
cmd=$1
db_username=$2
db_password=$3

# Start docker
# Make sure you understand the double pipe operator
sudo systemctl status docker || sudo systemctl start docker

# Check container status (try the following cmds on terminal)
docker container inspect jrvs-psql
container_status=$?

# User switch case to handle create|stop|start opetions
case $cmd in
  create)

  # Check if the container is already created
  if [ $container_status -eq 0 ]; then
		echo 'Container already exists'
		exit 1
	fi

  # Check # of CLI arguments
  if [ $# -ne 3 ]; then
    echo 'Create requires username and password'
    exit 1
  fi

  # Create psql image and run its container
  docker pull postgres
	docker volume create pgdata
  docker run -d \
    --name jrvs-psql \
    -e POSTGRES_USER=$db_username \
    -e POSTGRES_PASSWORD=$db_password \
    -v pgdata:/var/lib/postgresql/data \
    -p 5432:5432 \
    postgres:9.6-alpine

	exit $?
	;;

start|stop)
  # Check instance status; exit 1 if container has not been created
  if [ $container_status -ne 0 ]; then
    echo 'Container has not been created'
    exit 1
  fi

  # Start or stop the container
	docker container $cmd jrvs-psql
	exit $?
	;;

*)
	echo 'Illegal command'
	echo 'Commands: start|stop|create'
	exit 1
	;;
esac
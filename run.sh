#!/bin/bash

DOCKER_CONTAINER_LOCAL=story_db-local

options=("Start server" "Setup DB" "Connect to DB with psql client" "Stop/Remove containers" "quit")
PS3='What do you want to do? '
select action in "${options[@]}"; do
	case $action in
	"Start server")
		case $DEV_ENV in
		local)
			cd src && export DEV_ENV=$DEV_ENV && go run server.go
			;;
		esac
		;;
	"Setup DB")
        printf "\n"
		case $DEV_ENV in
		# sed -i -e 's/\r$//' runsql.sh  (this is for removing line endings for Windows compatibility)
		local)
			docker exec -it $DOCKER_CONTAINER_LOCAL /bin/sh -c "./runsql.sh"
			;;
		esac
		;;
	"Connect to DB with psql client")
		case $DEV_ENV in
		local)
			docker exec -it $DOCKER_CONTAINER_LOCAL /bin/sh -c "psql --dbname=$INSTANCE_DB --host=$DB_HOST --port=$DB_PORT --username=$DB_USERNAME --set=sslmode=disable"
			;;
		esac
		;;
	"Stop/Remove containers")
		case $DEV_ENV in
		local)
			docker-compose -f docker/local/docker-compose.local.yml down --remove-orphans
			;;
		esac
		;;
	"quit")
		printf "\nBye."
		exit 0
		;;
	*) echo "invalid option" ;;
	esac
	break
done

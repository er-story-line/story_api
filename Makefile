DOCKER_LOCAL_CONTAINER=story_db-local
DB_NAME=story_

init:
	mkdir -p src/keys
	# bearer token jwt authentication
	openssl genrsa 512 > ./src/keys/private-key.pem
	openssl rsa -in ./src/keys/private-key.pem -pubout -out ./src/keys/public-key.pem
	# install dep
	curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
	dep ensure
	# stop any containers if they are currently running
	docker-compose -f docker/local/docker-compose.local.yml down
	# pull and create the images
	docker-compose -f docker/local/docker-compose.local.yml build --no-cache
local_build_containers:
	docker-compose -f docker/local/docker-compose.local.yml build
local_enter_psql_container:
	docker exec -it $(DOCKER_LOCAL_CONTAINER) /bin/sh
local_psql_connect:
	docker exec -it $(DOCKER_LOCAL_CONTAINER) /bin/sh -c \
		"psql --host=localhost --port=5432 --username=postgres --dbname=$(DB_NAME)"
local_start_server:
	cd src && go run server.go
local_modify_db:
	docker exec -it $(DOCKER_LOCAL_CONTAINER) /bin/sh -c "./runsql.sh"


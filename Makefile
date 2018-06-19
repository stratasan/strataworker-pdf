all: plan deploy

build:
	docker-compose build

run:
	docker-compose run strataworker-pdf

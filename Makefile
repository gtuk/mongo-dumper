.PHONY: help docker-build docker-push

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

docker-build: ## Build all docker images
	docker login
	@echo "Building image for mongo-3.4"
	docker build --no-cache --build-arg MONGODB_VERSION=3.4 -t gtuk/mongo-dumper:mongo-3.4 .
	@echo "Building image for mongo-5.0"
	docker build --no-cache --build-arg MONGODB_VERSION=5.0 -t gtuk/mongo-dumper:mongo-5.0 .
	@echo "Building image for mongo-4.4"
	docker build --no-cache --build-arg MONGODB_VERSION=4.4 -t gtuk/mongo-dumper:mongo-4.4 .

docker-publish: docker-build ## Publish all docker images
	@echo "Pushing image gtuk/mongo-dumper/mongo-3.4"
	docker push gtuk/mongo-dumper:mongo-3.4
	@echo "Pushing image gtuk/mongo-dumper/mongo-5.0"
	docker push gtuk/mongo-dumper:mongo-5.0
	@echo "Pushing image gtuk/mongo-dumper/mongo-4.4"
	docker push gtuk/mongo-dumper:mongo-4.4

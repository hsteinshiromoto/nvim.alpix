SHELL:=/bin/bash
.DEFAULT_GOAL := help
.PHONY: help docs

# ---
# Variables
# ---
# include .env
# export $(shell sed 's/=.*//' .env)

HOST_ARCH=$(shell uname -m)
PROJECT_PATH := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
GIT_REMOTE=$(shell basename $(shell git remote get-url origin))
PROJECT_NAME=$(shell echo $(GIT_REMOTE:.git=))
CURRENT_VERSION=$(shell git tag -l --sort=-creatordate | head -n 1 | cut -d "v" -f2-)
QUARTZ_PATH=/usr/local/quartz

DOCKER_REGISTRY_USER=hsteinshiromoto
DOCKER_REGISTRY=ghcr.io
DOCKER_IMAGE_NAME=${DOCKER_REGISTRY}/${DOCKER_REGISTRY_USER}/${PROJECT_NAME}/${PROJECT_NAME}
DOCKER_TAG=$(shell git ls-files -s Dockerfile | awk '{print $$2}' | cut -c1-16)
DOCKER_PARENT_IMAGE=alpine:3.20.3

BUILD_DATE=$(shell date +%Y%m%d-%H:%M:%S)

# ---
# Commands
# ---

## Build Docker image
image:
	$(eval DOCKER_IMAGE_TAG=${DOCKER_IMAGE_NAME}:${DOCKER_TAG})

	@echo "Building docker image ${DOCKER_IMAGE_TAG}"
	docker buildx build --build-arg BUILD_DATE=${BUILD_DATE} \
				--build-arg DOCKER_PARENT_IMAGE=${DOCKER_PARENT_IMAGE} \
				--platform linux/${HOST_ARCH} \
				-t ${DOCKER_IMAGE_TAG} .

	docker tag ${DOCKER_IMAGE_TAG} ${DOCKER_IMAGE_NAME}:latest
	@echo "Done"

## Push Docker image to registry
push: image
	$(eval DOCKER_IMAGE_TAG=${DOCKER_IMAGE_NAME}:${DOCKER_TAG})
	@echo "Pushing Docker image ${DOCKER_IMAGE_NAME} to ${DOCKER_REGISTRY} ..."
	docker push ${DOCKER_IMAGE_NAME}
	@echo "Done"

## Pull Docker image from repository
pull:
	$(eval DOCKER_IMAGE_TAG=${DOCKER_IMAGE_NAME}:${DOCKER_TAG})

	@echo "Pulling Docker image ${DOCKER_IMAGE_TAG} from ${DOCKER_REGISTRY} ..."
	docker pull ${DOCKER_IMAGE_TAG}
	@echo "Done"

## Run Docker container
run:
	$(eval DOCKER_IMAGE_TAG=${DOCKER_IMAGE_NAME}:${DOCKER_TAG})

	@echo "Running docker image ${DOCKER_IMAGE_TAG} ..."


# ---
# Self Documenting Commands
# ---

.DEFAULT_GOAL := help

# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
# sed script explained:
# /^##/:
# 	* save line in hold space
# 	* purge line
# 	* Loop:
# 		* append newline + line to hold space
# 		* go to next line
# 		* if line starts with doc comment, strip comment character off and loop
# 	* remove target prerequisites
# 	* append hold space (+ newline) to line
# 	* replace newline plus comments by `---`
# 	* print line
# Separate expressions are necessary because labels cannot be delimited by
# semicolon; see <http://stackoverflow.com/a/11799865/1968>
.PHONY: help
help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')

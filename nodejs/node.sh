#!/bin/bash
# Bash wrappers for docker run commands

node(){
	docker run --rm -it \
		--name nodejs \
		-v "$(pwd):/app/" \
		-w /app \
		-p 3000:3000 \
		node:lts-alpine "$@"
}

npm(){
	docker run --rm -it \
		--name nodejs \
		-v "$(pwd):/app/" \
		-w /app \
		-p 3000:3000 \
		node:lts-alpine npm "$@"
}
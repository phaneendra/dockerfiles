#!/bin/bash
# Bash wrappers for docker run commands

htpasswd(){
	docker run --rm -it \
		--net none \
		--name htpasswd \
		--log-driver none \
		jess/htpasswd "$@"
}
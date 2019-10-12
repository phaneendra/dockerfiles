#!/bin/bash
# Bash wrappers for docker run commands

hugo(){
	docker run --rm -it \
		--name hugo \
    -v ${HUGO_SRCDIR}:/src \
		-v ${HUGO_OUTPUTDIR}:/target \
		-e HUGO_THEME="academic" \
		-p 1313:1313 \
		klakegg/hugo:0.55.6-ext-alpine "$@"
}
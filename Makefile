.PHONY: install healthchecks all

all:
	make install && make registry && make healthchecks

healthchecks:
	cp healthchecks.env healthchecks/docker && \
	cd healthchecks/docker && docker compose up -d

healthchecks-clean:
	cp healthchecks.env healthchecks/docker && \
	cd healthchecks/docker && docker compose down -v && docker compose up -d

install:
	sudo cp -r nginx/ /etc && sudo systemctl restart nginx && sudo systemctl status nginx

registry:
	docker rm --force registry && docker run -e REGISTRY_HTTP_HOST=https://registry.yungstentech.com \
		-d -p 5000:5000 --restart=always --name registry \
    -v `pwd`/registry.yaml:/etc/docker/registry/config.yml \
		-v /var/lib/registry:/var/lib/registry \
    registry:2 && \
	docker rm --force docker-registry-frontend && docker run \
		-d \
		--name docker-registry-frontend \
		-e ENV_DOCKER_REGISTRY_HOST=registry.yungstentech.com \
		-e ENV_DOCKER_REGISTRY_PORT=443 \
		-e ENV_DOCKER_REGISTRY_USE_SSL=1 \
		-p 8080:80 \
		konradkleine/docker-registry-frontend:v2
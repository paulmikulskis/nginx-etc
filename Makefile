.PHONY: nginx healthchecks all healthchecks-superuser healthchecks-env infisical infisical-env posty posty-frontend posty-api
ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
all:
	make nginx && make registry && make healthchecks && make infisical

healthchecks-env:
	cd healthchecks && \
	git submodule init && \
	git submodule update && \
	cd .. && \
	cp healthchecks.env healthchecks/docker/.env

# if deploying healthchecks and there is no superuser, make a superuser
healthchecks-superuser:
	docker compose -f healthchecks/docker/docker-compose.yml run web ./manage.py \
	shell -c \
	"from django.contrib.auth.models import User; User.objects.create_superuser('${DJANGO_USERNAME}', '${DJANGO_EMAIL}', '${DJANGO_PASSWORD}' )"

healthchecks:
	make healthchecks-env && \
	docker compose -f healthchecks/docker/docker-compose.yml up -d --force-recreate

infisical-env:
	cp infisical.env infisical/.env

infisical:
	make infisical-env && \
	docker compose --env-file infisical.env -f infisical/docker-compose.yml up -d --force-recreate

healthchecks-clean:
	make healthchecks-env && \
	docker compose -f healthchecks/docker/docker-compose.yml down -v && \
	make healthchecks && \
	sleep 10 && \
	make healthchecks-superuser

posty:
	make posty-backend && make posty-frontend
posty-frontend:
	docker stop posty-frontend && \
	docker run --rm --name posty -d -p 1199:3000 registry.yungstentech.com/posty-frontend:latest
posty-api:
	docker stop posty-api && \
	docker run --rm --name posty-api -d -p 1198:1198 -v "${ROOT_DIR}"/../posty-backend-config:/etc/api-config registry.yungstentech.com/posty-api:latest

nginx:
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
		
loki:
	docker run --name loki -d -v $(pwd)/loki:/mnt/config -p 3100:3100 grafana/loki:2.7.0 -config.file=/mnt/config/loki-config.yaml
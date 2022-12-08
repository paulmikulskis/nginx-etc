.PHONY: nginx healthchecks all healthchecks-superuser healthchecks-env

all:
	make nginx && make registry && make healthchecks

healthchecks-env:
	cp healthchecks.env healthchecks/docker/.env
	
healthchecks:
	make healthchecks-env && \
	docker compose -f healthchecks/docker/docker-compose.yml up -d && \
	make healthchecks-superuser

healthchecks-superuser:
	make healthchecks-env && \
	sleep 10 && \
  docker compose -f healthchecks/docker/docker-compose.yml run web ./manage.py \
	shell -c \
	"from django.contrib.auth.models import User; User.objects.create_superuser('admin', '${DJANGO_EMAIL}', '${DJANGO_PASSWORD}' )"

healthchecks-clean:
	make healthchecks-env && \
	docker compose -f healthchecks/docker/docker-compose.yml down -v && \
	make healthchecks

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
		
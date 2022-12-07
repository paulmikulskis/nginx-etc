.PHONY: install


install:
	sudo cp -r nginx/ /etc && sudo systemctl restart nginx && sudo systemctl status nginx

registry:
	docker rm --force registry && docker run -e REGISTRY_HTTP_HOST=https://registry.yungstentech.com \
		-d -p 5000:5000 --restart=always --name registry \
    -v `pwd`/registry.yaml:/etc/docker/registry/config.yml \
    registry:2
.PHONY: install


install:
	sudo cp -r nginx/ /etc && sudo systemctl restart nginx && sudo systemctl status nginx
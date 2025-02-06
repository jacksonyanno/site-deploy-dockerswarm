default:
	@echo "\033[1;32mConstruindo imagem `webpage`...\033[0m"
	docker build -t webpage .
	@echo "\033[1;32mCriando e executadno o container `webpage` na porta 8080...\033[0m"
	docker run --name webpage -v ./conf/default.conf:/etc/nginx/conf.d/default.conf:ro -d -p 8080:80 	webpage

ls:
	@echo "\033[1;32mListando imagens docker...\033[0m"
	docker image ls
	@echo "\033[1;32mListando containers docker em execução...\033[0m"
	docker ps

rmc:
	@echo "\033[1;32mExcluindo o container `webpage` na porta 8080...\033[0m"
	docker rm -f webpage

rmi:
	@echo "\033[1;32mExcluindo a imagem `webpage`...\033[0m"
	docker image rm webpage

rm: rmc rmi

FROM nginx:alpine

# Copia site para diretório do servidor
COPY ./src/. /var/www/html

EXPOSE 80
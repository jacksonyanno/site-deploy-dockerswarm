# Introdução
Este projeto tem como objetivo facilitar a implantação de um _site_ em um cluster [Docker Swarm (Swarm mode)](https://docs.docker.com/engine/swarm/), usando [Traefik Proxy](https://doc.traefik.io/traefik/) como proxy reverso e SSL. Ele foi implantado em servidores da [Digital Ocean (DO)](https://www.digitalocean.com/).
  
É importante frizar que, atualmente, a tecnologia de orquestração de conteiners mais utilizada no mercado é o [Kubernetes](https://kubernetes.io/), por sua robustez e amplo suporte. Portanto, para ambientes de produção e/ou homologação, recomenda-se utilizar o `Kubernetes` ou `serviços de nuvem gerenciados`. 
  
Pela simplicidade do `Docker Swarm Mode`, essa pode ser uma ótima ferramenta para implantação de sítios e sistemas em ambientes de desenvolvimento e/ou testes.

# Pré-requisitos
**1.** Ter o sistema operacional [Ubuntu 20.04 LTS (Focal Fossa)](https://releases.ubuntu.com/focal/) ou superior instalado na própria máquina
**2.** Ter, pelo menos, 2 (dois) servidores na [Digital Ocean (DO)](https://www.digitalocean.com/) com sistema operacional `Ubuntu 20.04 LTS (Focal Fossa)` ou superior
**3.** Configurar os servidores remotos configurados com o `Docker Swarm Mode`, com pelo menos um nó `manager` e outro `worker` ([link](#instalação-e-configuração-do-docker-e-do-modo-swarm)) 
**4.** Ter um `domínio` apontando para o IP do servidor remoto que esteja configurado como configurado como nó `manager` ([link](#obtenção-e-configuração-de-um-domínio))

# Configurações
## Acesso aos servidores remotos via SSH sem senha
**1.** Instalar o Update Droplet Console (DigitalOcean) no Ubuntu local
```sh
wget -qO- https://repos-droplet.digitalocean.com/install.sh | sudo bash
```
**2.** Acessar servidor por meio da interface da DigitalOcean
> Usar interface da DO por meio [deste link](https://cloud.digitalocean.com/login)

**3.** Permitir acesso aos servidores remotos por senha (repetir este procedimetno para cada servidor)
```sh
nano /etc/ssh/sshd_config
```
```sh
# alterar 'PasswordAuthentication' de 'no' para 'yes'
PasswordAuthentication yes
```
```sh
# reiniciar o serviço sshd
systemctl restart sshd
```

**4.** Gerar um par de chaves privada/pública no Ubuntu local
```sh
# irá gerar o por de chaves 'id_rsa' e 'id_rsa.pub' em .ssh/
ssh-keygen -t rsa
```

**5.** Copiar a chave pública para os servidores remotos
```sh
# a chave copiada será armazenada em '~/.ssh/authorized_keys' do servidor remoto 
ssh-copy-id user@server-ip-manager
ssh-copy-id user@server-ip-worker
```

**6.** Revogar acesso ao servidor remoto por senha (repetir este procedimetno para cada servidor)
```sh
nano /etc/ssh/sshd_config
```
```sh
# alterar 'PasswordAuthentication' de 'yes' para 'no'
PasswordAuthentication no
```
```sh
# reiniciar o serviço sshd
systemctl restart sshd
```

## Instalação e configuração do `Docker Engine` e do `Docker Swarm Mode`
**1.** Instalar e configurar o `Docker Engine` no `sistema operacional local` e nos `servidores da Digital Ocean` ([Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/))
```sh
# instalar atualizações mais recentes do sistema
apt-get update
apt-get upgrade -y
```
```sh
# instalar o Docker via script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh ./get-docker.sh --dry-run
```
```sh
# adicionar o usuário ao grupo docker
sudo usermod -aG docker $USER
```
**2.** Configurar o modo Swarm no servidores remotos ([Create a swarm](https://docs.docker.com/engine/swarm/swarm-tutorial/create-swarm/))
- `MANAGER NODE`
```sh
# acessar o servidor que será o nó 'manager'
ssh user@server-ip-manager
```
```sh
# iniciar o swarm mode
# a flag  '--advertise-addr' configura o nó manager para publicar seu endereço como <MANAGER-IP>
# Os outros nós do swarm devem poder acessar o manager no endereço IP <MANAGER-IP>. 
docker swarm init --advertise-addr <MANAGER-IP>
```
```sh
# exemplo de saída
docker swarm init --advertise-addr 19**2.**168.99.100
Swarm initialized: current node (dxn1zf6l61qsb1josjja83ngz) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join \
    --token SWMTKN-1-49nj1cmql0jkz5s954yi3oex3nedyz0fb0xx14ie39trti4wxv-8vxv8rssmk743ojnwacrr2e7c \
    19**2.**168.99.100:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```

- `WORKER NODE`
```sh
# acessar o servidor que será o nó 'worker'
ssh user@server-ip-worker
```
```sh
# ingressar o servidor no cluster swarm como um nó 'worker' 
docker swarm join \
  --token  SWMTKN-1-49nj1cmql0jkz5s954yi3oex3nedyz0fb0xx14ie39trti4wxv-8vxv8rssmk743ojnwacrr2e7c \
  19**2.**168.99.100:2377

This node joined a swarm as a worker.
```
- Acesse a máquina configrada como nó `manager` via `ssh` e executado o comando `docker node ls` para ver os nós do cluster:
```sh
# exemplo de saída
docker node ls
ID                           HOSTNAME  STATUS  AVAILABILITY  MANAGER STATUS
dxn1zf6l61qsb1josjja83ngz *  manager1  Ready   Active        Leader
9j68exjopxe7wfl6yuxml7a7j    worker1   Ready   Act
```

## Criação de um contexto Docker na máquina local apontando para o nó `manager`
A criação um contexto Docker na máquina local apontando para o nó `manager` permite a execução de `comandos docker` no servidor remoto a partir do terminal da máquina do usuário 
**1.** Adicionar um contexto docker do servidor remoto configurado como `manager` na máquina local
```sh
# criação do contexto com nome 'server-manager'
docker context create server-manager --docker "host=ssh://user@user@server-ip-manager"
```
**2.** Listar contextos existentes
```sh
# listar os contextos existentes. 
# o símbolo '*' indica o contexto selecionado atualmente
docker context ls
NAME            DESCRIPTION                               DOCKER ENDPOINT               ERROR
default *       Current DOCKER_HOST based configuration   unix:///var/run/docker.sock
server-manager                                            ssh://root@hom1
```
**3.** Selecionar um conexto específico
```sh
# seleção do contexto do servidor manager
# agora os comandos docker inseridos no terminal local serão executados no servidor remoto
docker context use server-manager
```

## Obtenção e configuração de um domínio
**1.** Neste ponto é necessário comprar um domínio ou obtê-lo de forma gratuita
    - É possível obter um domínio gratuito no site [Freenom - Domínios gratuitos](https://www.freenom.com/pt/index.html) 
**2.** De posse de um dominio (ex.: mysite.com), siga para a área de gerenciamento do seu domínio e subistitua os servidores de nomes  padrões (NS) pelos Name Servers da `Digital Ocean` para que seu domínio possa ser gerenciado pela `DO`
```sh
ns**1.**digitalocean.com
ns**2.**digitalocean.com
ns**3.**digitalocean.com
```
**3.** Adicionar seu domínio na Digital Ocean:  ([Add a domain](https://cloud.digitalocean.com/networking/domains))
**4.** No domínio adicionado, criar um registro do tipo `A` apontando para IP do `nó manager` e outro do tipo `CNAME`para seu domínio
```sh
*.mysite.com. 43200 IN CNAME mysite.com.
mysite.com. 3600 IN A <MANAGER-IP>
```

# Implantação do Traefik como Proxy reverso usando SSL no Docker Swarm
> É importante lembrar que, antes de executar os comandos a seguir, você deve alternar o docker para o contexto do servidor manager, criado em [seção anterior](#criar-um-contexto-docker-na-máquina-local-apontando-para-o-nó-manager) 

**1.** No gerenciamento de domínios da DO, configurar um registro `CNAME` apontando para endereço do domínio
```yml
traefik.mysite.com. 43200 IN CNAME mysite.com.
```

**2.** Definir as seguintes variáveis de ambiente
```sh
# usar um e-mail válido
export EMAIL=admin@example.com
```
```sh
# domínio da aplicação Traefik
export DOMAIN=traefik.mysite.com
```
```sh
# usuário e senha para autenticação no Traefik
export USERNAME=admin
export PASSWORD=my-pass
```
```sh
# cria o hash da senha
export HASHED_PASSWORD=$(openssl passwd -apr1 $PASSWORD)
```
```sh
# exibe o hash da senha
echo $HASHED_PASSWORD
```

**3.** Realizar as seguintes configurações  
```sh
docker network create --driver=overlay traefik-public
```
```sh
export NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')
```
```sh
docker node update --label-add traefik-public.traefik-public-certificates=true $NODE_ID
```

**4.** Fazer a implantação do Traefik
```sh
docker stack deploy -c traefik.yml traefik
```

**5.** Verificar se o serviço está ativo
```sh
docker stack ps traefik
docker service logs traefik_traefik -f
```

**6.** (OPCIONAL) Para baixar outras versões do arquivo Docker Compose de implantação do Traefik faça:
- Arquivo `traefik.yml` para Traefik v2
```sh
curl -L dockerswarm.rocks/traefik.yml -o traefik.yml
```
- Arquivo `traefik-v**3.**yml` para Traefik v3
```sh
curl -L dockerswarm.rocks/traefik-v**3.**yml -o traefik.yml
```

# Implantação do site
> É importante lembrar que, antes de executar os comandos a seguir, você deve alternar o docker para o contexto do servidor manager, criado em [seção anterior](#criar-um-contexto-docker-na-máquina-local-apontando-para-o-nó-manager) 

**1.** Copiar os arquivos do seu _site_ para o diretório `./src`, na raiz do projeto, deixando o `index.html`na raiz deste diretório
    - Os arquivos existentes tratam-se de um tema gratuito baixado do sítio [Themewagon](https://themewagon.com/theme-tag/html5-css3/) e devem ser substituídos pelos arquivos do seu _site_

**2.** Definir a variável de ambiente que será o domínio do site
```sh
export SITE_DOMAIN=mysite.com
```

**3.** Construir a imagem docker da aplicação
```sh
# o nome da imagem docker será webpage
docker build -t webpage .
# listar imagens para verificar se foi criada
docker image ls
```

**4.** Fazer a implantação do _site_
```sh
docker stack deploy -c stack-webpage-swarm.yml webpage
```

**5.** Verificar se o serviço está ativo
```sh
docker stack ps webpage
docker service logs webpage_webpage -f
```

**6.** Para remoção do site faça:
```sh
docker stack rm webpage
```

---
# Lançamento da Web Page no sistema local. 
> Certifique-se selecionar o contexto docker local (`default`), conforme aborado em [seção anterior](#criar-um-contexto-docker-na-máquina-local-apontando-para-o-nó-manager) 
## Criar uma imagem e servir a Web Page localmente
Para isso, basta executar o seguinte comando na raiz do projeto:
```sh
make
```
A página estará acessível na porta 8080

# Exclusão da Web Page localmente
Para remover o container e a imagem criados, execute:
```sh
make rm
```

# Referências
- https://docs.docker.com/engine/install/ubuntu/
- https://docs.docker.com/engine/swarm/swarm-tutorial/create-swarm/
- https://dockerswarm.rocks/traefik/


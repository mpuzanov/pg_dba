# Используемые команды

## Работа с ВМ в ЯО

```Bash

установка CLI - `curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash`
перезапуск bash - `source "/c/Users/manager/.bashrc"`

пример как переделать ключ для **yc**  
>sed '1s/^/ubuntu:/' /c/Users/manager/.ssh/yc_key.pub > /c/Users/manager/.ssh/yc_key.txt

yc compute instance create \
  --name vm-ubuntu \
  --hostname vm-ubuntu \
  --create-boot-disk size=15G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-2204-lts \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --memory 4G \
  --cores 2 \
  --core-fraction 5 \
  --preemptible \
  --zone ru-central1-a \
  --metadata-from-file ssh-keys=c:/Users/user/.ssh/yc_key.txt

ssh -i c:/Users/user/.ssh/id_ed25519  ubuntu@158.160.118.217
ssh -i c:/Users/manager/.ssh/yc_key  ubuntu@62.84.112.232

посмотреть внешний IP - `yc compute instance get vm-ubuntu`  
удаление ВМ - `yc compute instance delete --name=vm-ubuntu`  

```

## Установка Docker

```bash
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh && rm get-docker.sh && sudo usermod -aG docker $USER && newgrp docker

docker-compose up -d

docker-compose down

docker network create pg-net

docker run --name pg-server --network pg-net -e POSTGRES_PASSWORD=123 -d -p 5433:5432 -v /var/lib/postgres:/var/lib/postgresql/data postgres:15

docker run -dit --network=pg-net --name=pgclient codingpuss/postgres-client

```

## Docker-compose

```bash
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

Копирование файла docker-compose.yml на ВМ  

```bash
scp -i c:/Users/manager/.ssh/yc_key dz2/docker-compose.yml ubuntu@62.84.112.232:/home/ubuntu/
или с ключом по умолчанию на другую ВМ
scp dz2/docker-compose.yml manager@100.74.3.63:/home/manager/

```

# Используемые команды

## Работа с ЯО

```bash

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
  --metadata-from-file ssh-keys=c:/Users/manager/.ssh/yc_key.txt

ssh -i c:/Users/manager/.ssh/yc_key  ubuntu@130.193.49.160

yc compute instance list

yc compute disk create --name first-disk --size 10 --description "disk for postgres"

yc compute disk list

yc compute instance attach-disk vm-ubuntu --disk-name first-disk --mode rw

yc compute instance restart --name=vm-ubuntu

```

## Монтирование Диска

Выполняю на ВМ

``` bash

sudo parted -l | grep Error
вывод: Error: /dev/vdb: unrecognised disk label

-- стандарт разбиения
sudo parted /dev/vdb mklabel gpt

-- создать новый раздел
sudo parted -a opt /dev/vdb mkpart primary ext4 0% 100%

-- проверить
lsblk

-- создать файловую систему на новом разделе
sudo mkfs.ext4 -L mylabel /dev/vdb1
-- проверить
sudo lsblk --fs

-- смонтируем новую файловую систему
sudo mkdir -p /mnt/data  -- создаем каталог
sudo mount -o defaults /dev/vdb1 /mnt/data   -- временное монтирование

-- Автоматическое монтирование файловой системы при загрузке
sudo nano /etc/fstab
-- добавить строку
LABEL=mylabel /mnt/data ext4 defaults 0 2

-- Тестирование монтирования
sudo mount -a
df -h -x tmpfs

```

## Работа с PostgreSQL

``` bash

-- Установка Postgres на ВМ:
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt-get -y install postgresql-15 && sudo apt install unzip && sudo apt -y install mc

```

## Задание со *

```bash

yc compute instance create \
  --name vm-ubuntu2 \
  --hostname vm-ubuntu2 \
  --create-boot-disk size=15G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-2204-lts \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --memory 4G \
  --cores 2 \
  --core-fraction 5 \
  --preemptible \
  --zone ru-central1-a \
  --metadata-from-file ssh-keys=c:/Users/manager/.ssh/yc_key.txt

yc compute instance get --full vm-ubuntu
yc compute instance detach-disk vm-ubuntu --disk-id fhmj7gqtucpjv4nveucn
yc compute instance attach-disk vm-ubuntu2 --disk-name first-disk --mode rw

ssh -i c:/Users/manager/.ssh/yc_key  ubuntu@158.160.106.149

sudo mkdir -p /mnt/data  -- создаем каталог
sudo mount -o defaults /dev/vdb1 /mnt/data   -- временное монтирование
df -h -x tmpfs

sudo rm -R /var/lib/postgresql

sudo nano /etc/postgresql/15/main/postgresql.conf

```

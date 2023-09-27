# Используемые команды в ДЗ

```bash

-- Создать инстанс ВМ №1
yc compute instance create \
  --name vm-ubuntu1 \
  --hostname vm-ubuntu1 \
  --create-boot-disk size=10G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-2204-lts \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --memory 4G \
  --cores 2 \
  --core-fraction 5 \
  --preemptible \
  --zone ru-central1-a \
  --metadata-from-file ssh-keys=c:/Users/manager/.ssh/yc_key.txt

-- Создать инстанс ВМ №2
yc compute instance create \
  --name vm-ubuntu2 \
  --hostname vm-ubuntu2 \
  --create-boot-disk size=10G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-2204-lts \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --memory 4G \
  --cores 2 \
  --core-fraction 5 \
  --preemptible \
  --zone ru-central1-a \
  --metadata-from-file ssh-keys=c:/Users/manager/.ssh/yc_key.txt

-- Создать инстанс ВМ №3
yc compute instance create \
  --name vm-ubuntu3 \
  --hostname vm-ubuntu3 \
  --create-boot-disk size=10G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-2204-lts \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --memory 4G \
  --cores 2 \
  --core-fraction 5 \
  --preemptible \
  --zone ru-central1-a \
  --metadata-from-file ssh-keys=c:/Users/manager/.ssh/yc_key.txt

-- Создать инстанс ВМ №4
yc compute instance create \
  --name vm-ubuntu4 \
  --hostname vm-ubuntu4 \
  --create-boot-disk size=10G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-2204-lts \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --memory 4G \
  --cores 2 \
  --core-fraction 5 \
  --preemptible \
  --zone ru-central1-a \
  --metadata-from-file ssh-keys=c:/Users/manager/.ssh/yc_key.txt

158.160.32.109
158.160.53.229
158.160.125.109
158.160.100.213

ssh -i c:/Users/manager/.ssh/yc_key  ubuntu@158.160.32.109
ssh -i c:/Users/manager/.ssh/yc_key  ubuntu@158.160.53.229
ssh -i c:/Users/manager/.ssh/yc_key  ubuntu@158.160.125.109
ssh -i c:/Users/manager/.ssh/yc_key  ubuntu@158.160.100.213

yc compute instance delete --name=vm-ubuntu1
yc compute instance delete --name=vm-ubuntu2
yc compute instance delete --name=vm-ubuntu3
yc compute instance delete --name=vm-ubuntu4
```

```bash

-- Установка Postgres на ВМ:
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt-get -y install postgresql-15 && sudo apt install unzip && sudo apt -y install mc

pg_lsclusters

-- создадим пользователя для репликации
sudo -u postgres psql -d postgres -c "CREATE ROLE repl_user WITH SUPERUSER LOGIN REPLICATION PASSWORD '123';"

-- разрешим удалённые подключения на всех 4-х созданных ВМ
sudo pg_conftool 15 main set listen_addresses '*'
sudo su -c 'echo "host  all repl_user 0.0.0.0/0 scram-sha-256" >> /etc/postgresql/15/main/pg_hba.conf'

-- на ВМ1 и ВМ2
sudo -u postgres psql -c "ALTER SYSTEM SET wal_level = logical;"
sudo pg_ctlcluster 15 main restart

sudo -u postgres psql
```

```sql

-- Создадим базу для тестов на 3-х вирт.машинах
create database db_test;
\c db_test
-- Создание таблиц на 3-х вирт.машинах
create table test(id INT GENERATED ALWAYS AS IDENTITY, name VARCHAR(50));
create table test2(id INT GENERATED ALWAYS AS IDENTITY, name VARCHAR(50));

-- Настройка логической репликации (необходимых подписок)

-- создаём публикации в тестовой базе db_test
-- на ВМ1 158.160.32.109
CREATE PUBLICATION db_pub FOR TABLE test;
-- на ВМ2 158.160.53.229
CREATE PUBLICATION db_pub2 FOR TABLE test2;

-- создаем подписки
-- на ВМ1 158.160.32.109
CREATE SUBSCRIPTION db_sub CONNECTION 'host=158.160.53.229 user=repl_user password=123 dbname=db_test' PUBLICATION db_pub2;

-- на ВМ2 158.160.53.229
CREATE SUBSCRIPTION db_sub CONNECTION 'host=158.160.32.109 user=repl_user password=123 dbname=db_test' PUBLICATION db_pub;

-- на ВМ3 158.160.125.109
CREATE SUBSCRIPTION db_sub_v1 CONNECTION 'host=158.160.32.109 user=repl_user password=123 dbname=db_test' PUBLICATION db_pub;
CREATE SUBSCRIPTION db_sub_v2 CONNECTION 'host=158.160.53.229 user=repl_user password=123 dbname=db_test' PUBLICATION db_pub2;

-- проверка
-- на ВМ1
insert into test(name) values('t1 1'), ('t1 2');
-- на ВМ2
insert into test2(name) values('t2 1'), ('t2 2');
-- проверяем на 3-х ВМ
select * from test;select * from test2;

```

```bash
-- Настройка физической репликации с ВМ3 -> ВМ4

-- на ВМ3 158.160.125.109
sudo -u postgres psql -c "show wal_level;"  # replica

-- добавляем строку в pg_hba.conf
sudo su -c 'echo "host  replication repl_user 158.160.100.213/32 scram-sha-256" >> /etc/postgresql/15/main/pg_hba.conf'

sudo pg_ctlcluster 15 main restart

--====================================================================
-- на ВМ4 158.160.100.213

sudo su -c 'echo "host  replication repl_user 158.160.125.109/32 scram-sha-256" >> /etc/postgresql/15/main/pg_hba.conf'

sudo pg_ctlcluster 15 main restart

sudo -u postgres psql -c "show data_directory;"
sudo rm -rf /var/lib/postgresql/15/main
sudo -u postgres pg_basebackup -p 5432 -h 158.160.125.109 -U repl_user -R -D /var/lib/postgresql/15/main

sudo su -c 'echo "hot_standby = on" >> /var/lib/postgresql/15/main/postgresql.auto.conf'
sudo pg_ctlcluster 15 main start
pg_lsclusters
sudo -u postgres psql
```

```sql
--Проверим состояние репликации:
--на ВМ3
SELECT * FROM pg_stat_replication \gx

--на ВМ4
select * from pg_stat_wal_receiver \gx

\c db_test
select * from test;select * from test2;
```

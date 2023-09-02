# Используемые команды в ДЗ

```bash

-- Создать инстанс ВМ с 2 ядрами и 4 Гб ОЗУ и SSD 10GB
yc compute instance create \
  --name vm-ubuntu \
  --hostname vm-ubuntu \
  --create-boot-disk size=10G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-2204-lts \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --memory 4G \
  --cores 2 \
  --core-fraction 5 \
  --preemptible \
  --zone ru-central1-a \
  --metadata-from-file ssh-keys=c:/Users/manager/.ssh/yc_key.txt

ssh -i c:/Users/manager/.ssh/yc_key  ubuntu@84.201.135.170

yc compute instance delete --name=vm-ubuntu
```

```bash

-- Установка Postgres на ВМ:
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt-get -y install postgresql-15 && sudo apt install unzip && sudo apt -y install mc

pg_lsclusters

```

```sql

-- посмотреть кол-во мёртвых строк в таблице
SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_TABLEs WHERE relname = 't1';

-- анонимный блок, в котором в цикле 10 раз обновятся все строчки в искомой таблице
do $$
begin
 for i in 1..10 
 loop
   update t1 set "name" = md5(random()::text);      
   raise notice '% - выполнено', i;
 end loop;
end $$;

```

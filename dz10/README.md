# Домашнее задание Репликация

## Цель:

реализовать свой миникластер на 3 ВМ.

## Описание/Пошаговая инструкция выполнения домашнего задания:

На 1 ВМ создаем таблицы test для записи, test2 для запросов на чтение.  
Создаем публикацию таблицы test и подписываемся на публикацию таблицы test2 с ВМ №2.  
На 2 ВМ создаем таблицы test2 для записи, test для запросов на чтение.  
Создаем публикацию таблицы test2 и подписываемся на публикацию таблицы test1 с ВМ №1.  
3 ВМ использовать как реплику для чтения и бэкапов (подписаться на таблицы из ВМ №1 и №2 ).  

ДЗ сдается в виде миниотчета на гитхабе с описанием шагов и с какими проблемами столкнулись.
реализовать горячее реплицирование для высокой доступности на 4ВМ. 
Источником должна выступать ВМ №3. Написать с какими проблемами столкнулись.

![Реалезуемая схема репликации](./dz10.JPG)

Создал 4 виртуальные машины в яндекс облаке.  
Использовал команды в файле [command.md](./command.md)  
Установил на них PostgreSQL   
Создал пользователя для репликации на 4-х ВМ  
> sudo -u postgres psql -d postgres -c "CREATE ROLE repl_user WITH SUPERUSER LOGIN REPLICATION PASSWORD '123';"

Разрешил удалённые подключения в файлах (postgresql.conf, pg_hba.conf)  
Установил на ВМ1 и ВМ2 wal_level = logical  
Создадал базу **db_test** для тестов на 3-х вирт.машинах  
Создал таблицы на 3-х вирт.машинах  
Создал публикации и подписки  

```sql
-- Настройка логической репликации

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

id | name 
----+------
  1 | t1 1
  2 | t1 2
(2 rows)

 id | name
----+------
  1 | t2 1
  2 | t2 2
(2 rows)
```

Далее задание со *  
Настройка физической репликации с ВМ3 -> ВМ4  
```bash

-- на ВМ3 158.160.125.109

-- проверим тип журнала - должен быть #replica
sudo -u postgres psql -c "show wal_level;"  

-- добавляем строку в pg_hba.conf
sudo su -c 'echo "host  replication repl_user 158.160.100.213/32 scram-sha-256" >> /etc/postgresql/15/main/pg_hba.conf'

-- перестартуем
sudo pg_ctlcluster 15 main restart

------------------------------------------------------
-- на ВМ4 158.160.100.213

-- добавляем строку в pg_hba.conf
sudo su -c 'echo "host  replication repl_user 158.160.125.109/32 scram-sha-256" >> /etc/postgresql/15/main/pg_hba.conf'

sudo pg_ctlcluster 15 main restart

sudo -u postgres psql -c "show data_directory;"
-- удаляем каталог
sudo rm -rf /var/lib/postgresql/15/main

-- создаём архив с репликацией
sudo -u postgres pg_basebackup -p 5432 -h 158.160.125.109 -U repl_user -R -D /var/lib/postgresql/15/main

sudo su -c 'echo "hot_standby = on" >> /var/lib/postgresql/15/main/postgresql.auto.conf'
sudo pg_ctlcluster 15 main start
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
-- таблицы с данными на месте
```
Трудности были с правами пользователя для репликации и строкой для файла pg_hba.conf

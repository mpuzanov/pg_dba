# ДЗ: Работа с базами данных, пользователями и правами

Работа с базами данных, пользователями и правами

Цель:
создание новой базы данных, схемы и таблицы  
создание роли для чтения данных из созданной схемы созданной базы данных  
создание роли для чтения и записи из созданной схемы созданной базы данных  

Описание/Пошаговая инструкция выполнения домашнего задания:

1 создайте новый кластер PostgresSQL 14
> 14  main    5432 online postgres /var/lib/postgresql/14/main /var/log/postgresql/postgresql-14-main.log  

2 зайдите в созданный кластер под пользователем postgres
> sudo -u postgres psql

3 создайте новую базу данных testdb
> create database testdb;  
> \l

4 зайдите в созданную базу данных под пользователем postgres
> \c testdb

5 создайте новую схему testnm
> create schema testnm;  
> \dn  

6 создайте новую таблицу t1 с одной колонкой c1 типа integer
> create table t1 (c1 integer);

7 вставьте строку со значением c1=1
> insert into t1 values(1);

8 создайте новую роль readonly
> create role readonly;

9 дайте новой роли право на подключение к базе данных testdb
> grant connect on database testdb to readonly;

10 дайте новой роли право на использование схемы testnm
> grant usage on schema testnm to readonly;

11 дайте новой роли право на select для всех таблиц схемы testnm
> grant select on all tables in schema testnm to readonly;  

12 создайте пользователя testread с паролем test123
> create user testread with password 'test123';

13 дайте роль readonly пользователю testread
> grant readonly to testread;

14 зайдите под пользователем testread в базу данных testdb  
> изменил файл `/etc/postgresql/14/main/pg_hba.conf`, заменил peer для локального входа на scram-sha-256  
> перезапустил кластер `sudo pg_ctlcluster 14 main restart`  
> psql -U testread -d testdb -W

15 сделайте `select * from t1;`
> ОШИБКА:  нет доступа к таблице t1

16 получилось? (могло если вы делали сами не по шпаргалке и не упустили один 
существенный момент про который позже)
17 напишите что именно произошло в тексте домашнего задания
18 у вас есть идеи почему? ведь права то дали?
> таблица t1 была создана в схеме public, а к ней доступа нет у пользователя testread  

19 посмотрите на список таблиц
>\dt
>public | t1  | таблица | postgres

20 подсказка в шпаргалке под пунктом 20
21 а почему так получилось с таблицей (если делали сами и без шпаргалки то 
может у вас все нормально)
> если при создании таблицы схема не задана то испоьзуется переменная **search_path**  
> show search_path;  => "$user", public  
> так как схемы пользователя нет то таблица создана в схеме public  

22 вернитесь в базу данных testdb под пользователем postgres
> sudo -u postgres psql  
> \c testdb  

23 удалите таблицу t1
> drop table t1;

24 создайте ее заново но уже с явным указанием имени схемы testnm
> create table testnm.t1 (c1 integer);

25 вставьте строку со значением c1=1
> insert into testnm.t1 values(1);

26 зайдите под пользователем testread в базу данных testdb
> \c testdb testread

27 сделайте `select * from testnm.t1;`  
28 получилось?
> ОШИБКА:  нет доступа к таблице t1

29 есть идеи почему? если нет - смотрите шпаргалку
> надо обновить права на SELECT таблиц, потому что таблица пересоздавалась  

30 как сделать так чтобы такое больше не повторялось? если нет идей - 
смотрите шпаргалку
> \c testdb postgres
> ALTER default privileges in SCHEMA testnm grant SELECT on TABLES to readonly;  
> \c testdb testread

31 сделайте `select * from testnm.t1;`
> ОШИБКА:  нет доступа к таблице t1 
32 получилось?

33 есть идеи почему? если нет - смотрите шпаргалку
> \c testdb postgres  
> grant select on all tables in schema testnm to readonly;  
> \c testdb testread  

31 сделайте `select * from testnm.t1;`
32 получилось?
> да, получилось

33 ура!
34 теперь попробуйте выполнить команду `create table t2(c1 integer); insert into t2 values (2);`

35 а как так? нам же никто прав на создание таблиц и insert в них под ролью readonly?
> роль `public` добавляется всем новым пользователям  
> в PostgreSQL-14 по умолчанию роли `public` даётся право GRANT на все действия в схеме `public`

36 есть идеи как убрать эти права? если нет - смотрите шпаргалку
> \c testdb postgres;  
> REVOKE CREATE on SCHEMA public FROM public;  
> REVOKE ALL on DATABASE testdb FROM public;  
> \c testdb testread;  

37 если вы справились сами то расскажите что сделали и почему, если смотрели шпаргалку - объясните что сделали и почему выполнив указанные в ней команды
> убрали право создания объектов в схеме public у роли public  
> убрали все права в базе testdb у роли public  

38 теперь попробуйте выполнить команду `create table t3(c1 integer); insert into t2 values (2);`
> ОШИБКА:  нет доступа к схеме public

39 расскажите что получилось и почему
> теперь прав на создание объектов в схеме public у роли public, а соответственно и пользователю testread НЕТ.

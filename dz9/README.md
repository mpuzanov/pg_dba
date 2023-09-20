# Домашнее задание № 9 Бэкапы

## Цель:

Применить логический бэкап. Восстановиться из бэкапа


## Описание/Пошаговая инструкция выполнения домашнего задания:

Создаем ВМ/докер c ПГ.

Создаем БД, схему и в ней таблицу.

```sql
create database test;
\c test
create schema my;
create table my.t1(id int, name varchar(10));
```
Заполним таблицы автосгенерированными 100 записями.

```sql
insert  into my.t1
select 
  generate_series(1,100) as id,
  md5(random()::text)::char(10) as name;
```

Под линукс пользователем Postgres создадим каталог для бэкапов

```bash
sudo mkdir /usr/backup
chown postgres /usr/backup
```
Сделаем логический бэкап используя утилиту COPY

```sql
copy my.t1 to '/usr/backup/t1.sql';
```

Восстановим в 2 таблицу данные из бэкапа.

```sql
create table my.t2(id int, name varchar(10));
copy my.t2 from '/usr/backup/t1.sql';
```

Используя утилиту pg_dump создадим бэкап в кастомном сжатом формате двух таблиц

```bash
pg_dump -d test -Fc -U postgres > /usr/backup/test.dump
# с дополнительным сжатием
pg_dump -d test -Fc -U postgres | gzip > /usr/backup/test.dump.gz
# с выбором таблиц
pg_dump -t my.t* test -Fc -U postgres > /usr/backup/test_table.dump

```

Используя утилиту pg_restore восстановим в новую БД только вторую таблицу!

```sql
create database test2;
\c test2
create schema my;
```

```bash
pg_restore -U postgres -d test2 --table=t2 /usr/backup/test.dump

# если не создавать схему в ручную то можно 
# вначале схему создать из архива, а потом только данные залить
pg_restore -U postgres -d test2 --schema-only /usr/backup/test.dump
pg_restore -U postgres -d test2 --data-only --table=t2 /usr/backup/test.dump
```
>select * from my.t2;

# ДЗ: Настройка autovacuum с учетом особенностей производительности

**Цель:**  

запустить нагрузочный тест pgbench  
настроить параметры autovacuum  
проверить работу autovacuum  

## Описание/Пошаговая инструкция выполнения домашнего задания:

Создать инстанс ВМ с 2 ядрами и 4 Гб ОЗУ и SSD 10GB
>создал на Yandex Cloud

Установить на него PostgreSQL 15 с дефолтными настройками
>установил

Создать БД для тестов: выполнить `pgbench -i postgres`
Запустить `pgbench -c8 -P 6 -T 60 -U postgres postgres`
>sudo su postgres  
>pgbench -i postgres  
>pgbench -c8 -P 6 -T 60 -U postgres postgres  
>tps = 184.471020 (without initial connection time)

Применить параметры настройки PostgreSQL из прикрепленного к материалам занятия файла
>используя `sudo pg_conftool 15 main set <параметр>` изменил значения параметров  
>sudo pg_ctlcluster 15 main restart  

Протестировать заново. Что изменилось и почему?
>sudo su postgres  
>pgbench -c8 -P 6 -T 60 -U postgres postgres  
>tps = 163.795996 (without initial connection time)
>новые настройки ухудшили производительность 

Создать таблицу с текстовым полем и заполнить случайными или сгенерированными данным в размере 1млн строк
> sudo -u postgres psql  
```sql
create table t1 as
select md5(random()::text) as name
from generate_series(1,1000000);
```

Посмотреть размер файла с таблицей
>SELECT pg_size_pretty(pg_total_relation_size('t1'));
>65 MB

5 раз обновить все строчки и добавить к каждой строчке любой символ

```sql
do $$
begin
 for i in 1..5 
 loop
   update t1 
   set "name" = concat("name",chr(((random() * (127 - 32))::int + 32)));
   raise notice 'выполнено - %', i;
 end loop;
end $$;
```

Посмотреть количество мертвых строчек в таблице и когда последний раз приходил автовакуум  
>SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_TABLEs WHERE relname = 't1';  
>
>t1      |    1000000 |    5000000 |    499 | 2023-09-02 15:07:21.176147+00  
>Мёртвых строк 5 000 000  

Подождать некоторое время, проверяя, пришел ли автовакуум
>прошёл  
>t1      |    1000000 |          0 |      0 | 2023-09-02 15:10:25.334042+00

5 раз обновить все строчки и добавить к каждой строчке любой символ
Посмотреть размер файла с таблицей
>415 MB

Отключить Автовакуум на конкретной таблице
>ALTER TABLE t1 SET (autovacuum_enabled = off);  

10 раз обновить все строчки и добавить к каждой строчке любой символ

```sql
do $$
begin
 for i in 1..10
 loop
   update t1 
   set "name" = concat("name",chr(((random() * (127 - 32))::int + 32)));
   raise notice 'выполнено - %', i;
 end loop;
end $$;
```

Посмотреть размер файла с таблицей
>841 MB

Объясните полученный результат
>при обновлении происходит вставка строк с новыми значениями,  
>а старые строки просто помечаются как удалённые.  
>Автовакуум не сжимает таблицу  

Не забудьте включить автовакуум)
>ALTER TABLE t1 SET (autovacuum_enabled = on);  

Задание со *:  
Написать анонимную процедуру, в которой в цикле 10 раз обновятся все строчки в искомой таблице.
Не забыть вывести номер шага цикла.

```sql
do $$
begin
 for i in 1..10 
 loop
   update t1 set "name" = md5(random()::text);
   raise notice 'выполнено - %', i;
 end loop;
end $$;
```

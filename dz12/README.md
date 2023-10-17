# Домашнее задание Секционирование таблицы

Цель:
научиться секционировать таблицы.


## Описание/Пошаговая инструкция выполнения домашнего задания:

Секционировать большую таблицу из демо базы flights

скачал демо базу и установил 
>sudo -u postgres psql -c "\i demo_big.sql"

определил таблицу и поле для секционирования
> выбрал таблицу **flights** (Рейсы) и поле **sheduled_departure** (запланированная дата вылета)

создал скрипт для создания секционированных таблиц

```postgresql
-- создание секционированной таблицы (на базе flights)
create table flights_range(like flights) partition by range (scheduled_departure);

-- создание секций для хранения по месяцам и архивным данным
create table flights_range_201611 partition of flights_range for values from ('2016-11-01'::timestamptz) TO ('2016-12-01'::timestamptz);
create table flights_range_201610 partition of flights_range for values from ('2016-10-01'::timestamptz) TO ('2016-11-01'::timestamptz);
create table flights_range_201609 partition of flights_range for values from ('2016-09-01'::timestamptz) TO ('2016-10-01'::timestamptz);
create table flights_range_201608 partition of flights_range for values from ('2016-08-01'::timestamptz) TO ('2016-09-01'::timestamptz);
-- секция для архивных данных (без разбивки по периодам)
create table flights_range_history partition of flights_range for values from ('2015-01-01'::timestamptz) TO ('2016-08-01'::timestamptz);

-- копирование данных
INSERT INTO flights_range SELECT * FROM flights;
```

сравнил результаты выполнения запроса на стандартной таблице и секционированной

```postgresql
-- на обычной таблице
explain analyze 
SELECT * FROM flights where scheduled_departure between ('2016-08-01'::timestamptz) and ('2016-09-30'::timestamptz);

-- QUERY PLAN
Seq Scan on flights  (cost=0.00..5847.00 rows=32548 width=63) (actual time=0.019..29.520 rows=32591 loops=1)
  Filter: ((scheduled_departure >= '2016-08-01 00:00:00+04'::timestamp with time zone) AND (scheduled_departure <= '2016-09-30 00:00:00+04'::timestamp with time zone))
  Rows Removed by Filter: 182276
Planning Time: 0.129 ms
Execution Time: 30.868 ms

-- на секционированной
explain analyze 
SELECT * FROM flights_range where scheduled_departure between ('2016-08-01'::timestamptz) and ('2016-09-30'::timestamptz);

-- QUERY PLAN
Append  (cost=0.00..1070.97 rows=32577 width=63) (actual time=0.015..11.216 rows=32591 loops=1)
  ->  Seq Scan on flights_range_201608 flights_range_1  (cost=0.00..461.81 rows=16851 width=63) (actual time=0.014..5.023 rows=16854 loops=1)
        Filter: ((scheduled_departure >= '2016-08-01 00:00:00+04'::timestamp with time zone) AND (scheduled_departure <= '2016-09-30 00:00:00+04'::timestamp with time zone))
  ->  Seq Scan on flights_range_201609 flights_range_2  (cost=0.00..446.27 rows=15726 width=63) (actual time=0.009..2.837 rows=15737 loops=1)
        Filter: ((scheduled_departure >= '2016-08-01 00:00:00+04'::timestamp with time zone) AND (scheduled_departure <= '2016-09-30 00:00:00+04'::timestamp with time zone))
        Rows Removed by Filter: 548
Planning Time: 0.217 ms
Execution Time: 12.939 ms
```
На секционированной таблице запрос выполняется быстрее, так как используются только нужные секции.

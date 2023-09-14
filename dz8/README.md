# Домашнее задание № 7 Нагрузочное тестирование и тюнинг PostgreSQL

Цель:
- сделать нагрузочное тестирование PostgreSQL
- настроить параметры PostgreSQL для достижения максимальной производительности

**Описание/Пошаговая инструкция выполнения домашнего задания:**  

• развернуть виртуальную машину любым удобным способом
>создал на Yandex Cloud

• поставить на неё PostgreSQL 15 любым способом
>установил

• настроить кластер PostgreSQL 15 на максимальную производительность не
обращая внимание на возможные проблемы с надежностью в случае
аварийной перезагрузки виртуальной машины
• нагрузить кластер через утилиту через утилиту pgbench (https://postgrespro.ru/docs/postgrespro/14/pgbench)
• написать какого значения tps удалось достичь, показать какие параметры в
какие значения устанавливали и почему

```sql
--создадим бд для тестов
sudo -u postgres psql
create database testdb;
--подготовим тестовые таблицы
sudo -u postgres pgbench -i testdb
sudo -u postgres pgbench -c 10 -j 2 -P 10 -T 30 testdb
tps = 144.763098 -- эталон tps

-- менял разные значения параметров с помощью ALTER SYSTEM SET согласно рекомендациям
-- shared_buffers, work_mem, effective_cache_size, checkpoint_timeout
-- после изменения параметров перезапускаем кластер 
$sudo pg_ctlcluster 15 main restart
-- но выигрыш в скорости по pgbench получил только изменив synchronous_commit
ALTER SYSTEM SET synchronous_commit = off;
tps = 880.809195
--В режиме off отсутствует ожидание сброса WAL на диск. При сбое ОС или БД возможна потеря последних нескольких транзакций. Но параметр даёт выигрыш в скорости работы.  
```

Задание со *: аналогично протестировать через утилиту https://github.com/Percona-Lab/sysbench-tpcc 
(требует установки https://github.com/akopytov/sysbench)

```bash
# Тестировал на своём сервере
# установил sysbench
$ curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | sudo bash
$ sudo apt -y install sysbench
# sysbench тоже может тестировать Postgresql


# Утилита sysbench-tpcc
git clone https://github.com/digoal/sysbench-tpcc  
cd sysbench-tpcc
chmod 700 *.lua

1. Подготовка таблиц для тестов
./tpcc.lua --pgsql-port=5432 --pgsql-user=sbtest --pgsql-db=sbtest --threads=64 --tables=10 --scale=10 --trx_level=RC --db-ps-mode=auto --db-driver=pgsql --pgsql-password=password prepare

2. Запуск теста
./tpcc.lua --pgsql-user=sbtest --pgsql-db=sbtest --time=300 --threads=24 --report-interval=1 --tables=10 --scale=10 --use_fk=0 --trx_level=RC --pgsql-password=password --db-driver=pgsql run

Выдаёт информацию:

SQL statistics:
    queries performed:
        read:                            668946
        write:                           695188
        other:                           114972
        total:                           1479106
    transactions:                        51474  (419.61 per sec.)
    queries:                             1479106 (12057.59 per sec.)
    ignored errors:                      214    (1.74 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          122.6678s
    total number of events:              51474

Latency (ms):
         min:                                    0.73
         avg:                                   57.02
         max:                                 3726.19
         95th percentile:                      308.84
         sum:                              2935257.37

Threads fairness:
    events (avg/stddev):           2144.7500/19.22
    execution time (avg/stddev):   122.3024/0.30


3. Очистка после тестов
./tpcc.lua --pgsql-port=5432 --pgsql-user=sbtest --pgsql-db=sbtest --threads=24 --tables=10 --scale=10 --trx_level=RC --db-driver=pgsql --pgsql-password=password cleanup

```
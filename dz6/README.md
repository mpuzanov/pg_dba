# Домашнее задание N6 Работа с журналами

**Цель:**  
уметь работать с журналами и контрольными точками  
уметь настраивать параметры журналов  

**Описание/Пошаговая инструкция выполнения домашнего задания:**  

Настройте выполнение контрольной точки раз в 30 секунд.
>show checkpoint_timeout;  
>ALTER SYSTEM SET checkpoint_timeout= '30s';  
>sudo pg_ctlcluster 15 main restart  

10 минут c помощью утилиты pgbench подавайте нагрузку.
>sudo su postgres
>pgbench -i postgres  
>SELECT pg_size_pretty(sum(size)) as size_files FROM pg_ls_waldir();
>32 MB
>pgbench -c8 -P 30 -T 600 -U postgres postgres  

Измерьте, какой объем журнальных файлов был сгенерирован за это время. Оцените, какой объем приходится в среднем на одну контрольную точку.
>SELECT pg_size_pretty(sum(size)) as size_files FROM pg_ls_waldir();  
>64 MB  
>64/(600/30) = 3.3 MB  

Проверьте данные статистики: все ли контрольные точки выполнялись точно по расписанию. Почему так произошло?
>cat /var/log/postgresql/postgresql-15-main.log  
>checkpoint выполнялись каждые 30 сек.  

Сравните tps в синхронном/асинхронном режиме утилитой pgbench. Объясните полученный результат.
>tps = 168.255387 (without initial connection time)  
>ALTER SYSTEM SET synchronous_commit = off;  
>sudo pg_ctlcluster 15 main restart  
>tps = 622.780609 (without initial connection time)  
>В режиме off отсутствует ожидание сброса WAL на диск. При сбое ОС или БД возможна потеря последних нескольких транзакций. Но параметр даёт выигрыш в скорости работы.  

Создайте новый кластер с включенной контрольной суммой страниц.  
>sudo -u postgres pg_createcluster 15 main2 -- --data-checksums  
>sudo pg_ctlcluster 15 main2 start  
>`15  main    5432 online postgres /var/lib/postgresql/15/main  /var/log/postgresql/postgresql-15-main.log`  
>`15  main2   5433 online postgres /var/lib/postgresql/15/main2 /var/log/postgresql/postgresql-15-main2.log`  

Создайте таблицу. Вставьте несколько значений.  
>sudo -u postgres psql -p 5433  

```sql
create table t1 as
select md5(random()::text) as name
from generate_series(1,10);
```

Выключите кластер. Измените пару байт в таблице.  
>SELECT pg_relation_filepath('t1');  
>base/5/16388
>sudo pg_ctlcluster 15 main2 stop  
>sudo dd if=/dev/zero of=/var/lib/postgresql/15/main2/base/5/16388 oflag=dsync conv=notrunc bs=1 count=8

Включите кластер и сделайте выборку из таблицы.  
>sudo pg_ctlcluster 15 main2 start  
>sudo -u postgres psql -p 5433 -c 'select * from t1;'  
>получил:
>WARNING:  page verification failed, calculated checksum 40183 but expected 62552
ERROR:  invalid page in block 0 of relation base/5/16388

Что и почему произошло? как проигнорировать ошибку и продолжить работу?  
>Контрольная сумма страницы с данными не та что ожидалась.
>Чтобы попытаться прочитать из таблицы можно задать `SET ignore_checksum_failure = on; select * from t1;`

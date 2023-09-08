# Домашнее задание № 7 Механизм блокировок

**Цель:**  

понимать как работает механизм блокировок объектов и строк

## Описание/Пошаговая инструкция выполнения домашнего задания

1. Настройте сервер так, чтобы в журнал сообщений сбрасывалась информация о блокировках, удерживаемых более 200 миллисекунд. Воспроизведите ситуацию, при которой в журнале появятся такие сообщения.

```sql
show deadlock_timeout;  (тек.значение: 1s)
show log_lock_waits;  (off)
ALTER SYSTEM SET log_lock_waits = on;
ALTER system set deadlock_timeout = 200;

SELECT pg_reload_conf();

-- подготовка данных для последующих тестов
create database locks;
\c locks
CREATE TABLE accounts(
  acc_no integer PRIMARY KEY,
  amount numeric
);
INSERT INTO accounts VALUES (1,1000.00), (2,2000.00), (3,3000.00);

-- session 1
BEGIN;
SELECT pg_backend_pid(); --25354
UPDATE accounts SET amount = amount + 100 WHERE acc_no = 1;

-- session 2
BEGIN;
SELECT pg_backend_pid(); --25355
CREATE INDEX ON accounts(acc_no);

-- появиться запись в журнале
```

>tail -n 10 /var/log/postgresql/postgresql-15-main.log
![журнал сообщений](./pg-block-log.JPG)

2. Смоделируйте ситуацию обновления одной и той же строки тремя командами UPDATE в разных сеансах. Изучите возникшие блокировки в представлении pg_locks и убедитесь, что все они понятны. Пришлите список блокировок и объясните, что значит каждая.

![сеанс 1](./session1.JPG)  

![сеанс 2](./session2.JPG)  

![сеанс 3](./session3.JPG)  

> Номер блокировки сеанса1 = 2206, сеанса2 = 2213, сеанса3 = 2218  
> 2213 ждёт 2206, а 2218 ждёт 2213  

3. Воспроизведите взаимоблокировку трех транзакций. Можно ли разобраться в ситуации постфактум, изучая журнал сообщений?

```sql
-- Session #1
BEGIN;
SELECT pg_backend_pid();  --25354
UPDATE accounts SET amount = amount - 100.00 WHERE acc_no = 1;
-- Session #2
BEGIN;
SELECT pg_backend_pid();  --25355
UPDATE accounts SET amount = amount - 10.00 WHERE acc_no = 2;
-- Session #3
BEGIN;
SELECT pg_backend_pid();  --25357
UPDATE accounts SET amount = amount - 20.00 WHERE acc_no = 3;

-- Session #1  меняет 2 запись
UPDATE accounts SET amount = amount + 100.00 WHERE acc_no = 2;
-- Session #2  меняет 3 запись
UPDATE accounts SET amount = amount + 10.00 WHERE acc_no = 3;
-- Session #3  меняет 1 запись
UPDATE accounts SET amount = amount + 20.00 WHERE acc_no = 1;
-- через deadlock_timeout сброс транзакции с ошибкой
ERROR:  deadlock detected
DETAIL:  Process 25357 waits for ShareLock on transaction 330859; blocked by process 25354.
Process 25354 waits for ShareLock on transaction 330860; blocked by process 25355.
Process 25355 waits for ShareLock on transaction 330861; blocked by process 25357.
HINT:  See server log for query details.
CONTEXT:  while updating tuple (0,7) in relation "accounts"
```

>tail -n 25 /var/log/postgresql/postgresql-15-main.log  
![журнал сообщений](./pg-block-log2.JPG)
> В журнале также видно что 25357 ждёт 25354, 25354 ждёт 25355, а 25355 ждёт 25357.

4. Могут ли две транзакции, выполняющие единственную команду UPDATE одной и той же таблицы (без where), заблокировать друг друга?

> В теории да, могут так как UPDATE блокирует строки по мере их обновления.  
> Например: в 1 сессии обновление идёт сверху вниз, а 2 сессии обновление происходит снизу вверх и они встречаются и ждут друг друга.  

Задание со звездочкой*
Попробуйте воспроизвести такую ситуацию.

```sql
-- создадим таблицу для примера
create table t1 as
select id, (random() * (1000 - 1) + 1)::numeric(9,2) as price
from generate_series(1,20) as t(id);
select * from t1;

-- создадим индекс в обратном порядке
CREATE INDEX ON t1(price DESC); 

-- функцию для замедленного обновления
CREATE OR REPLACE FUNCTION inc_price_slow(n numeric) RETURNS numeric AS $$
  SELECT pg_sleep(1);
  SELECT n + n*0.1;
$$ LANGUAGE SQL;

-- сеанс 1
UPDATE t1 SET price = inc_price_slow(price);

-- сеанс 2
SET enable_seqscan = off;
SHOW enable_seqscan;
UPDATE t1 SET price = inc_price_slow(price) WHERE price> 1.00;


--в 1 сеансе
ERROR:  deadlock detected
DETAIL:  Process 2206 waits for ShareLock on transaction 330835; blocked by process 2213.
Process 2213 waits for ShareLock on transaction 330836; blocked by process 2206.

```

**PS**: правда во 2 сеансе всё равно пришлось использовать WHERE без него по индексу UPDATE не получался. Но думаю что это пока из-за недостаточного знания возможностей команд SQL в Postgresql.

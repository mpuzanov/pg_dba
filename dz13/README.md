# Домашнее задание Работа с join'ами, статистикой

## Цель:

знать и уметь применять различные виды join'ов
строить и анализировать план выполнения запроса
оптимизировать запрос
уметь собирать и анализировать статистику для таблицы

## Описание/Пошаговая инструкция выполнения домашнего задания:

В результате выполнения ДЗ вы научитесь пользоваться
различными вариантами соединения таблиц.
В данном задании тренируются навыки:
написания запросов с различными типами соединений

## Необходимо:

Для выполнения домашнего задания взял демо базу данных flights

Реализовать прямое соединение двух или более таблиц

```postgresql
-- кто забронировал билет на заданную дату
select b.book_date, t.passenger_name, t.contact_data
from bookings as b
    join tickets t on
        b.book_ref = t.book_ref
where DATE(b.book_date)='2016-08-28';  -- или b.book_date>='2016-08-28' and b.book_date<'2016-08-29';  
```

Реализовать левостороннее (или правостороннее) соединение двух или более таблиц
```postgresql
-- вывод список всех самолётов даже если у них не было рейсов 2016-08-28
select air.model, f.flight_no, f.departure_airport, f.arrival_airport, f.actual_departure
from aircrafts as air
    left join flights f on
        air.aircraft_code = f.aircraft_code
        and DATE(f.actual_departure)='2016-08-28';
```

Реализовать кросс соединение двух или более таблиц
```postgresql
-- объединение каждой строки первой таблицы с каждой строкой второй таблицы
-- просто для примера пересечение аэропортов и самолётов
select air.model, p.airport_name
from aircrafts as air
cross join airports as p;
```

Реализовать полное соединение двух или более таблиц
```postgresql
-- в выборке будут все строки таблиц, даже если они не соответствуют условию
SELECT t.passenger_name, b.book_date
FROM tickets as t
FULL OUTER JOIN bookings b on t.book_ref = b.book_ref
and passenger_name='IVAN ZAKHAROV'
where b.book_date='2016-08-28 10:26'
order by passenger_name;

/*
IVAN ZAKHAROV,2016-08-28 10:26:00.000000 +00:00
,2016-08-28 10:26:00.000000 +00:00
,2016-08-28 10:26:00.000000 +00:00
,2016-08-28 10:26:00.000000 +00:00
,2016-08-28 10:26:00.000000 +00:00
,2016-08-28 10:26:00.000000 +00:00
 */
```

Реализовать запрос, в котором будут использованы разные типы соединений
```postgresql
-- Список пустых мест на заданном рейсе
select s.seat_no, bp.ticket_no, f.departure_airport, f.arrival_airport, a.model, f.actual_departure
from aircrafts a
    join seats s on a.aircraft_code = s.aircraft_code
    join flights as f on f.aircraft_code = a.aircraft_code
    left join boarding_passes bp on f.flight_id = bp.flight_id and s.seat_no=bp.seat_no
where f.flight_id=116681
and bp.ticket_no is null;
```

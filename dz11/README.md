# Домашнее задание Работа с индексами

## Цель:

знать и уметь применять основные виды индексов PostgreSQL
строить и анализировать план выполнения запроса
уметь оптимизировать запросы для с использованием индексов

### Описание/Пошаговая инструкция выполнения домашнего задания:

Создать индексы на БД, которые ускорят доступ к данным.
В данном задании тренируются навыки:

определения узких мест
написания запросов для создания индекса
оптимизации

## Необходимо:

Создать индекс к какой-либо из таблиц вашей БД

```postgresql
-- создадим таблицу с улицами
create table streets as
select generate_series as street_id
    , (array['Авангардная','Базисная','Зенитная','Кооперативная','Ломоносова','Дзержинского',
            'Оранжерейная','Бабушкина','Буммашевская','Герцена','Грибоедова','Жуковского'])[floor(random() * 12 + 1)] as name
    , (array['улица', 'проезд', 'проспект', 'переулок'])[floor(random() * 3 + 1)] as prefix
    , gen_random_uuid() as kod_fias
    , (array['Ижевск','Сарапул','Воткинск','Глазов','Можга'])[floor(random() * 5 + 1)] as town_name
from generate_series(1, 1000);
select * from streets;
--drop table if exists streets;

-- создадим индекс первичного ключа
alter table streets add constraint streets_id_pk primary key (street_id);
-- индекс для наименования улицы
create index idx_streets_name on streets(name);
```
Прислать текстом результат команды explain, в которой используется данный индекс

```postgresql
-- получим план запроса
explain
select * from streets where name='Дзержинского';
-- видим использование созданного индекса
Bitmap Heap Scan on streets  (cost=4.86..18.99 rows=91 width=67)
  Recheck Cond: (name = 'Дзержинского'::text)
  ->  Bitmap Index Scan on idx_streets_name  (cost=0.00..4.83 rows=91 width=0)
        Index Cond: (name = 'Дзержинского'::text)

```

Реализовать индекс на часть таблицы или индекс на поле с функцией

```postgresql
-- индекс на часть таблицы (город Ижевск чаще используется в поиске)
create index idx_streets_town_izhevsk on streets(town_name) where town_name = 'Ижевск';  
-- получим план запроса
explain
select * from streets where town_name = 'Ижевск';
-- видим использование созданного индекса
Bitmap Heap Scan on streets  (cost=9.23..24.82 rows=207 width=67)
  Recheck Cond: (town_name = 'Ижевск'::text)
  ->  Bitmap Index Scan on idx_streets_town_izhevsk  (cost=0.00..9.18 rows=207 width=0)

```
Создать индекс на несколько полей

```postgresql
-- индекс из 2-х полей
create index idx_street_name_prefix on streets(name, prefix);
-- получим план запроса
explain
select * from streets where name='Дзержинского' and prefix='улица';
-- видим использование созданного индекса
Bitmap Heap Scan on streets  (cost=4.57..18.01 rows=29 width=67)
  Recheck Cond: ((name = 'Дзержинского'::text) AND (prefix = 'улица'::text))
  ->  Bitmap Index Scan on idx_street_name_prefix  (cost=0.00..4.57 rows=29 width=0)
        Index Cond: ((name = 'Дзержинского'::text) AND (prefix = 'улица'::text))

```

Реализовать индекс для полнотекстового поиска

```postgresql
-- создадим таблицу для тестирования полнотекстового поиска
-- В таблице организации и начисляемые ей услуги
drop table if exists organizations;
create table organizations (
      name varchar(50) -- организайия ЖКХ
    , services_list text -- список начисляемых услуг
    , services_list_lexeme tsvector -- колонка для полнотекстового индекса
    );
insert into organizations(name, services_list)
select concat('Организация ', generate_series) as org_name
        , concat_ws(','
            , (array['Содержание жилья', 'Горячее водоснабжение', 'Холодное водоснабжение'])[(random() * 4)::int]
            , (array['Антенна', 'Видеорегистрация', 'Обращение с ТКО', 'Мусоропровод'])[(random() * 5)::int]
            , (array['Водоотведение', 'Обслуживание у/у', 'Обслуживание ИТП', 'Лифт'])[(random() * 5)::int]
            , (array['Благоустройство территории', 'Газ для ГВС', 'Консьерж', 'Отопление'])[(random() * 5)::int]
            )
from generate_series(1, 1000);
select * from organizations;

-- обновляем колонку для полнотекстового индекса
update organizations set services_list_lexeme = to_tsvector(services_list);

drop index if exists idx_organizations_services_list_lexeme;
-- создаём полтотекстовый индекс
create index idx_organizations_services_list_lexeme ON organizations using gin (services_list_lexeme);

-- узнаем список организаций ведущий расчет по услуге: Антенна
select name, services_list from organizations
where services_list_lexeme @@ to_tsquery('Антенна');
-- в тестовой выборке получил 217 из 1000 организаций 

-- получим план запроса
explain
select name, services_list from organizations
where services_list_lexeme @@ to_tsquery('Антенна');

-- результат explain видим что используется наш индекс
Bitmap Heap Scan on organizations  (cost=9.93..164.89 rows=217 width=117)
  Recheck Cond: (services_list_lexeme @@ to_tsquery('Антенна'::text))
  ->  Bitmap Index Scan on idx_organizations_services_list_lexeme  (cost=0.00..9.88 rows=217 width=0)
        Index Cond: (services_list_lexeme @@ to_tsquery('Антенна'::text))

```

# Домашнее задание по теме  Установка и настройка PostgreSQL в контейнере Docker

Цель:
установить PostgreSQL в Docker контейнере
настроить контейнер для внешнего подключения

Описание/Пошаговая инструкция выполнения домашнего задания:
• создать ВМ с Ubuntu 20.04/22.04 или развернуть докер любым удобным способом

> создал в Yandex Cloud
> подключился - `ssh -i c:/Users/user/.ssh/id_ed25519  ubuntu@158.160.118.217`

• поставить на нем Docker Engine

> установил -
> curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh && rm get-docker.sh && sudo usermod -aG docker $USER && newgrp docker

• сделать каталог /var/lib/postgres

> создал - `sudo mkdir /var/lib/postgres`

• развернуть контейнер с PostgreSQL 15 смонтировав в него /var/lib/postgresql

> sudo docker run --name pg-server --network pg-net -e POSTGRES_PASSWORD=123 -d -p 5432:5432 -v /var/lib/postgres:/var/lib/postgresql/data postgres:15.3

• развернуть контейнер с клиентом postgres

> sudo docker run -it --rm --network pg-net --name pg-client postgres:15.3 psql -h pg-server -U postgres
> проверил командой - `sudo docker ps -a`
> есть 2 контейнера - pg-client и pg-server

• подключится из контейнера с клиентом к контейнеру с сервером и сделать таблицу с парой строк

```sql
create table persons(id serial, first_name text, second_name text); 
insert into persons(first_name, second_name) values('ivan', 'ivanov'); 
insert into persons(first_name, second_name) values('petr', 'petrov'); 
```
• подключится к контейнеру с сервером с ноутбука/компьютера извне инстансов GCP/ЯО/места установки докера

```
запустил команды в WSL на локальной машине: 
psql -h 158.160.118.217 -U postgres
select * from persons; - получил данные
```

• удалить контейнер с сервером

>docker rm --force pg-server

• создать его заново

>sudo docker run --name pg-server --network pg-net -e POSTGRES_PASSWORD=123 -d -p 5432:5432 -v /var/lib/postgres:/var/lib/postgresql/data postgres:15.3

• подключится снова из контейнера с клиентом к контейнеру с сервером

> sudo docker run -it --rm --network pg-net --name pg-client postgres:15.3 psql -h pg-server -U postgres

• проверить, что данные остались на месте

> select * from persons; - данные на месте

• оставляйте в ЛК ДЗ комментарии что и как вы делали и как боролись с проблемами

PS:

Дополнительно создал контейнер с сервером через docker-compose:

- Установил docker-compose на ВМ
- Скопировал файл yml на ВМ
- Запустил контейнер pg-server через docker-compose
- подключился снова из контейнера с клиентом к контейнеру с сервером - всё работает

Команды, которые использовал находятся в файле - `command.md`

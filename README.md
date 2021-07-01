# kafka-connect-template
Опишем работу с собственными коннекторами на примере debezium

### Инициализируем Kafka кластер
- Создаем сам кластер
```bash
yc kafka cluster create --name kafka-connect --network-name ksenz-main --assign-public-ip --zone-ids ru-central1-b --brokers-count 1 --resource-preset s2.micro --disk-size 100 --disk-type network-ssd
```
- Создаем топики: служебный топик debezium и для выгруженных данных
```bash
yc kafka topic create --cluster-name kafka-connect --replication-factor 1 --partitions 1 pg-dev.public.tutorials
yc kafka topic create --cluster-name kafka-connect --cleanup-policy compact --replication-factor 1 --partitions 1 __debezium-heartbeat.pg-dev
```
- Создаем пользователя с доступом к этим топикам
```bash
yc kafka user create --cluster-name kafka-connect --password UserPassword \
--permission topic=__debezium-heartbeat.pg-dev,role=ACCESS_ROLE_CONSUMER,role=ACCESS_ROLE_PRODUCER \
--permission topic=pg-dev.public.tutorials,role=ACCESS_ROLE_CONSUMER,role=ACCESS_ROLE_PRODUCER \
user
```
- Посмотрим fqdn брокера, который был создан и заполним его в .env
```bash
yc kafka cluster list-hosts --name kafka-connect
```

### Инициализируем Postgresql кластер
- Создаем сам кластер, базу и пользователя
```bash
yc postgresql cluster create --name kafka-connect --network-name ksenz-main \
--host zone-id=ru-central1-b,assign-public-ip=true \
--user name=debezium,password=definitelynotpassword \
--database name=dbname,owner=debezium
```
- Заполняем настройку в connector-pg.properties - database.hostname, это fqdn хоста базы данных, который можно посмотеть в UI (строка подключения к кластеру на странице кластера или во вкладке хосты)

- Создаем таблицу с тестовыми данными. Например, в UI
```sql
CREATE TABLE tutorials(
   tutorial_id bigserial primary key,
   tutorial_title VARCHAR(100) NOT NULL,
   tutorial_author VARCHAR(40) NOT NULL
);

INSERT INTO tutorials(tutorial_title,tutorial_author) VALUES('first','Maxim');
INSERT INTO tutorials(tutorial_title,tutorial_author) VALUES('second','Maxim');
INSERT INTO tutorials(tutorial_title,tutorial_author) VALUES('third','Maxim');
```

- Необходимо выдать пользователю право на создание слотов репликации (это нужно для отслеживания изменений)
```bash
yc postgresql user update debezium --cluster-name kafka-connect --grants mdb_replication
```

- создаем публикацию для таблицы - для отслеживания изменений
```sql
CREATE PUBLICATION dbname_publication FOR TABLE public.tutorials;
```


### Запуск коннектора
- Необходимо скачать коннектор от debezuim
```bash
cd plugins
wget https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/1.6.0.Final/debezium-connector-postgres-1.6.0.Final-plugin.tar.gz
tar -xvf debezium-connector-postgres-1.6.0.Final-plugin.tar.gz
```

- Собрать docker образ
```bash
docker build --tag kafka-connect ./
```

- И запустить
```bash
docker run --rm --env-file .env \
-v $(shell pwd)/plugins:/home/appuser/plugins \
-v $(shell pwd)/src/connector-pg.properties:/home/appuser/config/connector.properties \
kafka-connect
```

### Полезные ссылки
- [Примеры от Debezium](https://github.com/debezium/debezium-examples)
- [Документация к Postgres коннектору](https://debezium.io/documentation/reference/connectors/postgresql.html)

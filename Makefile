init-kafka:
	yc kafka cluster create --name kafka-connect --network-name ksenz-main --assign-public-ip --zone-ids ru-central1-b --brokers-count 1 --resource-preset s2.micro --disk-size 100 --disk-type network-ssd
	yc kafka user create --cluster-name kafka-connect --password UserPassword \
	--permission topic=__debezium-heartbeat.pg-dev,role=ACCESS_ROLE_CONSUMER,role=ACCESS_ROLE_PRODUCER \
	--permission topic=pg-dev.public.tutorials,role=ACCESS_ROLE_CONSUMER,role=ACCESS_ROLE_PRODUCER \
	user
	yc kafka topic create --cluster-name kafka-connect --replication-factor 1 --partitions 1 pg-dev.public.tutorials
	yc kafka topic create --cluster-name kafka-connect --cleanup-policy compact --replication-factor 1 --partitions 1 __debezium-heartbeat.pg-dev
	yc kafka cluster list-hosts --name kafka-connect

init-pg:
	yc postgresql cluster create --name kafka-connect --network-name ksenz-main \
	--host zone-id=ru-central1-b,assign-public-ip=true \
	--user name=debezium,password=definitelynotpassword \
	--database name=dbname,owner=debezium
	yc postgresql user update debezium --cluster-name kafka-connect --grants mdb_replication

build:
	docker build --tag kafka-connect ./

clean:
	yc kafka cluster delete --name kafka-connect
	yc postgresql cluster delete --name kafka-connect

bash:
	docker run --rm --env-file .env -it kafka-connect bash

run: build
	docker run --rm --env-file .env \
	-v $(shell pwd)/plugins:/home/appuser/plugins \
	-v $(shell pwd)/src/connector-pg.properties:/home/appuser/config/connector.properties \
	kafka-connect

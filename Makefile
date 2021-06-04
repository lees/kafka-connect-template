init:
	yc kafka cluster create --name kafka-connect --network-name ksenz-main --assign-public-ip --zone-ids ru-central1-b --brokers-count 1 --resource-preset s2.micro --disk-size 100 --disk-type network-ssd
	yc kafka topic create --cluster-name kafka-connect --replication-factor 1 --partitions 3 topic
	yc kafka user create --cluster-name kafka-connect --password UserPassword --permission topic=topic,role=ACCESS_ROLE_CONSUMER,role=ACCESS_ROLE_PRODUCER user
	yc kafka cluster list-hosts --name kafka-connect

build:
	docker build --tag kafka-connect ./

clean:
	yc kafka cluster delete --name kafka-connect

bash:
	docker run --rm --env-file .env -it kafka-connect bash

run: build
	docker run --rm --env-file .env kafka-connect

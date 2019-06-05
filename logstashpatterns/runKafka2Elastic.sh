#!/bin/sh

docker run --rm --network=host -d --name Kafka2Elastic -v /usr/share/logstash/pipeline/kafka2Elastic:/usr/share/logstash/pipeline/ docker.elastic.co/logstash/logstash:7.1.1

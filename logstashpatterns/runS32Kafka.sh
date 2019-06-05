#!/bin/sh

docker run --rm --network=host -d --name S32Kafka -v /usr/share/logstash/pipeline/s32kafka:/usr/share/logstash/pipeline/ docker.elastic.co/logstash/logstash:7.1.1

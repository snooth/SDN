#!/bin/sh

docker run --rm --network=host -d --name syslog2Kafka -v /usr/share/logstash/pipeline/syslog2kafka:/usr/share/logstash/pipeline/ docker.elastic.co/logstash/logstash:7.1.1

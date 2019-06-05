#!/bin/sh

docker run --rm --network=host -d --name collectd2Kafka -v /usr/share/logstash/pipeline/collectd2kafka:/usr/share/logstash/pipeline/ docker.elastic.co/logstash/logstash:7.1.1

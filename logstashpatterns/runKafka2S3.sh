#!/bin/sh

docker run --rm --network=host -d --name kafka2s3 -v /usr/share/logstash/pipeline/kafka2s3:/usr/share/logstash/pipeline/ docker.elastic.co/logstash/logstash:7.1.1

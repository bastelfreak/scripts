#!/bin/bash
# unset http proxy, we don't want to tunnel localhost through a squid
http_proxy=''

# define the indicies ids
#for i in {211..462}; do
for i in 299 501 503 504 505 506 507 508 509 510 511; do
  echo $i;
  curl -XPUT "localhost:9200/graylog2_$i/_settings" -d '
{
    "index" : {
        "number_of_replicas" : 3
    }
}';
  echo '';
done

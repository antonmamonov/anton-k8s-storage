#!/bin/bash

# setup core synapse
CONTAINERNAME=antonstorage
IMAGENAME=antonm/antonstorage:v0.0.1

docker rm -f $CONTAINERNAME

docker run -t -d \
    -e DEBUG=true \
 --name $CONTAINERNAME $IMAGENAME

 docker exec -it $CONTAINERNAME /bin/bash
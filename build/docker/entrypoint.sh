#!/bin/bash 


exec /sample-serf/node -ca ${CLUSTER_ADDRS} $@

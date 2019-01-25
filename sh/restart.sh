#!/bin/bash

CUR_DIR=$(dirname $(readlink -f $0))
sh $CUR_DIR/stop.sh
sleep 1
sh $CUR_DIR/start.sh

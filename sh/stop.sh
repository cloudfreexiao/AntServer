#!/bin/bash

CUR_DIR=$(dirname $(readlink -f $0))
if [ ! -f "$CUR_DIR/server_dependency.sh" ]; then
  echo "Lack of file $CUR_DIR/server_dependency.sh" && exit -1
fi

. $CUR_DIR/server_dependency.sh


$GAME1_ON        && bash $CUR_DIR/game1.sh stop $GAME1_EXIT_PORT

$LOGIN_ON       && bash $CUR_DIR/login.sh stop
$CENTER_ON      && bash $CUR_DIR/center.sh stop

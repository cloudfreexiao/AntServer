#!/bin/bash

CUR_DIR=$(dirname $(readlink -f $0))

if [ ! -f "$CUR_DIR/server_dependency.sh" ]; then
  echo "Lack of file $CUR_DIR/server_dependency.sh" && exit -1
fi


. $CUR_DIR/server_dependency.sh

$CENTER_ON      && bash "$CUR_DIR/center.sh"    start release config.center
sleep 1s
$LOGIN_ON       && bash "$CUR_DIR/login.sh"     start release config.login

sleep 1s
$GAME1_ON        && bash "$CUR_DIR/game1.sh"    start release config.game1


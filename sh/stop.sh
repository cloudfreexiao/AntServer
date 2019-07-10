#!/bin/bash

CUR_DIR=$(dirname $(readlink -f $0))
if [ ! -f "$CUR_DIR/server_dependency.sh" ]; then
  echo "Lack of file $CUR_DIR/server_dependency.sh" && exit -1
fi

GAME1_EXIT_PORT=15030
BATTLE1_EXIT_PORT=15040
BATTLE2_EXIT_PORT=15041

. $CUR_DIR/server_dependency.sh


# $BATTLE2_ON      && bash "$CUR_DIR/battle2.sh" stop $BATTLE2_EXIT_PORT
$BATTLE1_ON      && bash "$CUR_DIR/battle1.sh" stop $BATTLE1_EXIT_PORT
$GAME1_ON        && bash "$CUR_DIR/game1.sh" stop $GAME1_EXIT_PORT

$LOGIN_ON       && bash "$CUR_DIR/login.sh" stop
$CENTER_ON      && bash "$CUR_DIR/center.sh" stop

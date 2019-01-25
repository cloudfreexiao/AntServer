#!/bin/sh

#参数1： 命令
# start[默认] 启动
# stop 停止
CMD=$1

#参数2： 类型
# release[默认] 后台启动
# debug 前台启动
MODE=$2

TMP=$PATH
. /etc/init.d/functions
PATH=$TMP

CUR_PATH=$(dirname $(readlink -f $0))
PID_FILE=$CUR_PATH/login.pid

if [ -z "$3" ]; then
  CONFIG=$CUR_PATH/config.login
else
  CONFIG=$CUR_PATH/$3
fi

#后台启动
function back(){
  echo -n $"Starting loginserver: "
  $CUR_PATH/../skynet/skynet $CONFIG
  if [ $? -eq 0 ]; then
    success && echo
  else
    failure && echo
  fi
}

#前台启动
function view(){
  debug_cfg=$CUR_PATH/debug_cfg.login
  sed -e 's/^logger/--logger/' -e 's/daemon/--daemon/' $CONFIG > $debug_cfg
  $CUR_PATH/../skynet/skynet $debug_cfg
}

function start(){
  case "$MODE" in
    release)
    #sh sh/log_name.sh login
      back
      ;;
    debug)
      view
      ;;
    *)
      echo "mode[$MODE] invalid param, please sure [release|debug]"
      exit 2
  esac
}

function stop(){
  if [ ! -f $PID_FILE ] ;then
    echo "not found pid file have no loginserver"
    exit 0
  fi

  pid=`cat $PID_FILE`
  exist_pid=`pgrep skynet | grep $pid`
  if [ -z "$exist_pid" ] ;then
    echo "have no loginserver"
    exit 0
  else
    echo -n $"$pid loginserver will killed"
    killproc -p $PID_FILE
    echo
  fi
}

case "$CMD" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  *)
    echo "$0 start [release|debug config] | $0 stop"
    exit 2
esac


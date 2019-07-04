#/bin/sh
if [ "$1" = "" ] | [ "$2" = "" ] | [ "$3" = "" ]; then
    echo "usage: monitor pid skynet_bin_path service_id_in_decimal"
    exit 1
fi
sudo stap mini_lua_bt.stp --skip-badvars -x $1 $2 $3 -g --suppress-time-limits -DMAXSTRINGLEN=65536 |tee a.bt
./flamegraph.pl --width=2400 a.bt >skynet.svg

#!/bin/sh
echo ************************************
echo Starting the replica Set
echo ************************************

sleep 30 | echo Sleeping 30

mongo mongodb://mongo-rs0-1:27017 mongoSetup.js

sleep 10 | echo Sleeping 10

mongo --host `mongo mongo-rs0-1:27017 --quiet --eval "db.isMaster()['primary']"` dbSetup.js
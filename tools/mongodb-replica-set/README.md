# MongoDB replica set

Simple MongoDB replica set docker compose file.

In order to use Transaction function in MongoDB, you need a set of a replicated databases named MongoDB replica set.

This project makes it easy to build a MongoDB replica set circumstances by using docker container.

## Requirements

This project uses a Docker container for virtualizing Database circumstances.
Therefore, **Docker** must be installed

To set localhost host environment, **Direnv** must be installed

**how to install direnv?**

install with brew

```sh
brew install direnv
```

set bash configuration(if you use bash)
set zsh configuration(if you use zsh)

```sh
vi ~/.bashrc or vi ~/.zshrc

# add below configuration
eval "$(direnv hook bash)" or eval "$(direnv hook zsh)"

# apply
source ~/.bashrc or source ~/.zshrc
```

## Installation

Pull all the necessary docker image from docker hub and set up replica set configuration

```bash
docker-compose up
```

Set host name so that localhost can connect to docker container's internal ip with given mongodb configuration setting

```bash
direnv allow
```

## Set host for connecting to docker inner network

Changing directory to /dev triggers direnv setting so that hostname mongo-rs0-1, mongo-rs0-2, mongo-rs0-3 will be registered in you pc

```sh
cd dev
```

If you have Err: **direnv: error .envrc is blocked** Run `direnv allow` to approve its content.

```bash
direnv allow
```

### Check which server is Primary node

```bash
docker exec mongodb-replica-set_mongo-rs0-1_1 bash -c 'mongo --eval "rs.status()"'
```

result
![Result](images/result1.png)

In members field you can find member who has "PRIMARY" in "stateStr" field, and that is a Primary Node

### Connect to replica set

```bash
mongo 'mongodb://test:test1234@mongo-rs0-1:27017,mongo-rs0-2:27018,mongo-rs0-3:27019/test?replicaSet=rs0'
```

### Connect to primary node

```bash
mongo --host `mongo mongo-rs0-1:27017 --quiet --eval "db.isMaster()['primary']"`
```

### Create Account

Create Admin Account

```bash
mongo
use admin
db.createUser({user: "root", pwd: "test1234", roles: [{ role: "root", db: "admin" }] });
```

Create Database and matching account

```bash
mongo
use testdb
db.createUser(
 { user: "test",
 pwd: "test1234",
 roles: ['readWrite','userAdmin'] } )
```

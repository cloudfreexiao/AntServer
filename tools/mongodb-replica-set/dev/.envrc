sudo chmod 777 /etc/hosts

if grep -Frq 'mongo-rs0-1' /etc/hosts
then
    echo 'Host name for mongo-rs0-1 already exists'
else
    echo '127.0.0.1  mongo-rs0-1' >> /etc/hosts
    echo 'Hostname: mongo-rs0-1 set'
fi

if grep -Frq 'mongo-rs0-2' /etc/hosts
then
    echo 'Host name for mongo-rs0-2 already exists'
else
    echo '127.0.0.1  mongo-rs0-2' >> /etc/hosts
    echo 'Hostname: mongo-rs0-2 set'
fi

if grep -Frq 'mongo-rs0-3' /etc/hosts
then
    echo 'Host name for mongo-rs0-3 already exists'
else
    echo '127.0.0.1  mongo-rs0-3' >> /etc/hosts
    echo 'Hostname: mongo-rs0-3 set'
fi
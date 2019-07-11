db.getSiblingDB('admin').createUser({
  user: 'root',
  pwd: 'test1234',
  roles: [{ role: 'root', db: 'admin' }]
});

db.getSiblingDB('test').createUser({
  user: 'test',
  pwd: 'test1234',
  roles: ['readWrite', 'userAdmin']
});

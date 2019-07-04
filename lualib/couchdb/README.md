# lua-resty-couchdb 

Lua resty minimal couchdb client

# Installation 

```bash
#luarocks install lua-resty-couchdb
```

# Usage 
```lua
local couch   = require 'resty.couchdb'
local config  = {
  host = 'https://localhost:5984',
  user = 'couchdb-user',
  password = 'couchdb-pass'
}
local couch   = couch.new(config)
local user = couch:db('_users')

-- create db
local res, err = user:create()

-- add rows
local res, err = user:post(data)

-- view
local res, err = user:view('room', 'booked', {
  inclusive_end = tostring(true), -- boolean not supported, must be string
  start_key = '"hello"', -- double quote required by couchdb
  end_key = '"world'
})

-- all docs
local res, err = user:all_docs({
  inclusive_end = tostring(true), -- boolean not supported, must be string
  start_key = '"hello"', -- double quote required by couchdb
  end_key = '"world'
})

-- delete db
local res, err = user:destory()


```

### API
Please refer to the CouchDB API documentation at [docs.couchdb.org](http://docs.couchdb.org/en/stable/http-api.html) for available
REST API.

#### configuration
This api should be called first to set the correct database parameter
before calling any database action method.

- database name eg: booking

#### get(id)
Get database value
- id document id
- return lua table

#### put(data)
Insert data to database
- id document id
- data *(table)* data to save

#### post(data)
Insert data to database
- id document id
- data *(table)* data to save


#### delete(id)
Delete data from database
- id document id

#### save(data)
Update existing data. This api will automatically get the latest rev to use for updating the data.
- id document id
- data *(table)* to save


#### view(design_name, view_name, opts)
Query rows of data using views
- design_name *(string)* couchdb design name
- view_name *(string)* couchdb view name
- opts *(table)* options parameter as [documented here](http://docs.couchdb.org/en/stable/api/ddoc/views.html).
  Important note: start\_key and end\_key must always surrounded by double quote and boolean value not supported.
  For boolean value, it should be converted to string using lua **tostring**

#### all_docs(opts)
Query rows of data using bulk api
- opts *(table)* options parameter as [documented here](http://docs.couchdb.org/en/stable/api/database/bulkapi.html).
  Important note: start\_key and end\_key must always surrounded by double quote and boolean value not supported.
  For boolean value, it should be converted to string using lua **tostring**


#### create()
Create new database name

#### destroy()
Delete database


## Reference
- [CouchDB API](http://docs.couchdb.org/en/stable/http-api.html)
- [CouchDB View Options](http://docs.couchdb.org/en/stable/api/ddoc/views.html)
- [Request documentation](https://github.com/request/request)

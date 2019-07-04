package.path = package.path .. ";../?.lua"

local i = require 'inspect'
local json = require 'cjson'
local couchdb = require 'couchdb'
local couch = couchdb.new({
  host = 'http://127.0.0.1:5984',
  user = 'admin',
  password = 'admin'
})

local db = couch:db('test')

require 'busted.runner'()

describe('Database', function()
  
  setup(function()
    local res, err = db:destroy() 
  end)

  it('Create test database', function()
    local res, err = db:create() 
    assert.are.equal(res.ok, true)
  end)

  it('Test build view query with string', function()
    local url = db.build_query_params('hello') 
    assert.are.equal(url, 'key="hello"')
  end)

  it('Test build view query with table', function()
    local url = db.build_query_params({ inclusive_key=tostring(true), start_key='"hello"', end_key='"world"' }) 
    assert.are.equal(url, 'start_key=%22hello%22&end_key=%22world%22&inclusive_key=true')
  end)

  it('Test all docs', function()
    local res, err = db:all_docs({ inclusive_key=tostring(true), start_key='"hello"', end_key='"world"' }) 
    assert.are.equal(res.offset, 0)
  end)

  it('Test compare table equal', function()
    local res =  db.is_table_equal({ hello = 'world' }, nil)
    assert.are.equal(res, false)
  end)

  it('Test compare table equal', function()
    local res =  db.is_table_equal({ hello = 'world' }, { hello = 'world' })
    assert.are.equal(res, true)
  end)

  it('Test compare table equal', function()
    local res =  db.is_table_equal({ hello = 'world' }, { hello = 'world', sumandak = 'tamparuli' })
    assert.are.equal(res, false)
  end)

  it('Test add doc', function()
    local res, err = db:put({ _id = 'hello', hello = 'world' })
    assert.are.equal(res.ok, true)
  end)

  it('Test save doc', function()
    local res, err = db:save({ _id = 'hello', hello = 'world', sumandak = 'tamparuli' })
    assert.are.equal(res.sumandak, 'tamparuli')
  end)

  it('Test delete doc', function()
    local doc, err = db:get('hello')
    local res, err = db:delete(doc)
    local data, err = db:get('hello')
    assert.are.equal(err.error, 'not_found')
  end)
end)

## Name

lua-resty-influx - OpenResty client writer for InfluxDB.

## Status

This library is in active development and is considered ready for production use.

## Description

This library provides an OpenResty interface to write data points to an InfluxDB server via UDP and HTTP interfaces. Object-based and buffering per-worker interfaces are provided.

## Synopsis

Object interface:

```lua
http {
	server {
		access_by_lua_block {
			local i = require "resty.influx.object"

			local influx, err =i:new({
				host = "127.0.0.1",
				port = 8086,
				proto = "http",
				db = "db",
				hostname = "localhost",
				auth = "user:password",
			})

			if (not influx) then
				ngx.say(err)
				return
			end

			influx:set_measurement("foo")
			influx:add_tag("foo", "bar")
			influx:add_field("value", 1)
			influx:buffer()

			-- add and buffer additional data points

			local ok, err = influx:flush()

			if (not ok) then
				ngx.say(err)
			end
		}
	}
}
```

Buffering interface:

```lua
http {
	init_worker_by_lua_block {
		local ibuf = require "resty.influx.buffer"

		local ok, err = ibuf.init({
			host = "127.0.0.1",
			port = 8089,
			proto = "udp",
		})

		if (not ok) then
			ngx.log(ngx.ERR, err)
		end
	}

	server {
		access_by_lua_block {
			local ibuf = require "resty.influx.buffer"

			ibuf.buffer({
				measurement = "foo",
				tags = {
					{ foo = "bar" }
				},
				fields = {
					{ value = 1 }
				}
			})
		}

		log_by_lua_block {
			local ibuf = require "resty.influx.buffer"

			ibuf.flush()
		}
	}
}
```

## Usage

### Options

lua-resty-influx provides a pure object-based interface, as well as a buffering interface that stores data points per-worker, and then buffers asynchronously via `ngx.timer.at`. Creation of the buffering interface should be handled in the `init_worker_by_lua` phase via the `resty.influx.buffer.init` function; creation of the object-oriented interface should be handled in your appropriate phase handler via `resty.influx.object:new`. In both cases, the following options are available:

#### host

*Default*: 127.0.0.1

Sets the host to which `ngx.socket.udp` and `resty.http` will attempt to connect.

#### port

*Default*: 8086

Sets the port to which `ngx.socket.udp` and `resty.http` will attempt to connect. Defaults to `8086` as the default protocol is HTTP.

#### db

*Default*: 'lua-resty-influx'

Sets the db to which `resty.http` will attempt to connect. This option is ignored when `udp` is the configured protocol.

#### hostname

*Default*: `host`

Sets the hostname to which `resty.http` will define the `Host` header for HTTP requests. By default, this is equal to the configured `host` option. This option is ignored when `udp` is the configured protocol.

#### proto

*Default*: http

Sets the protocol by which `resty.influx` will connect to the remote server. Note that UDP can present a significant performance improvement, particularly when sending many small sets of data points, at the cost of error handling and authentication.

#### precision

*Default*: ms

Sets the timestamp precision by which `resty.influx` will define timestamps. Currently, `ms`, `s`, and `none` are supported; when `none` is configured, no stamp will be sent as part of the line protocol message, and the remote Influx server will use nanosecond precision based on the server-local clock.

#### ssl

*Default*: false

Configures HTTP requests to perform a TLS handshake before sending data. This option is ignored when `udp` is the configured protocol.

#### auth

*Default*: ''

Sets the username and password presented to remote HTTP(S). This value must be given as a single string in the format `user:password`. This option is ignored when `udp` is the configured protocol.

### Object-Oriented Interface

The following methods are available via the object interface:

#### influx:set_measurement

*Syntax*: influx:set_measurement(string)

Sets the measurement for the data point associated with the current object.

#### influx:add_tag

*Syntax* influx:add_tag(key, value)

Adds a data point tag as a key-value pair. Keys and values are escaped according to (https://docs.influxdata.com/influxdb/v1.0/write_protocols/line_protocol_reference/).

#### influx:add_field

*Syntax*: influx:add_field(key, value)

Add a data point field as a key-value pair. Fields and values are escaped according to (https://docs.influxdata.com/influxdb/v1.0/write_protocols/line_protocol_reference/). Integer values (number values appended with an `i`) are properly interpolated.

#### influx:stamp

*Syntax*: influx:stamp(time?)

Stamps the data point associated with the current object, with an optional arbitrary value (must be provided as a number); otherwise, this stamps the object with the appropriate value based on the precision specified via the options given to `new` for the object interface.

#### influx:clear

*Syntax* influx:clear()

Clears the measurement, tags, and fields on the data point associated with the current object. Note that this is called internally when `buffer` or  `write` are called.

#### influx:buffer

*Syntax*: local ok, err = influx:buffer()

Buffer the contents of the data point associated with the current object for later flushing. Returns true on success; otherwise, returns false and a string describing the error (such as invalid conditions under which to buffer).

#### influx:flush

*Syntax*: local ok, err = influx:flush()

Flushes all buffered data points associated with the current object. Returns true on success; otherwise, returns false and a string describing the error (such as leftover data waiting to be buffered, or no available buffered data points).

#### influx:write

*Syntax* local ok, err = inflush:write()

Writes the data point associated with the current object, without clearing the existing object buffer. This is essentially shorthand for calling `buffer` and `flush` on a single data point. Note that previously buffered data points still remain in the buffer, and must be sent out via `flush` if desired.

### Buffering Interface

The following functions are available via the buffering interface:

#### influx.buffer

*Syntax*: influx.buffer(data_table)

Buffers a new data point in the per-worker process buffer. `data_table` must be a table that contains the following keys:

* `measurement`: String denoting the measurement of the data point
* `tags`: Integer-indexed table containing tables of key-value pairs denoting the tag elements. See the synopsis for examples.
* `fields`: Integer-indexed table containing tables of key-value pairs denoting the field elements. See the synopsis for examples.

Note that currently the timestamp is automatically set with `ms` precision.

#### influx.flush

*Syntax* influx.flush()

Write all data points buffered in the current worker process to the configured influx host. Returns true on success; otherwise, returns false and a string describing the error from `ngx.timer.at`.

This operation returns immediately and runs asynchronously

## License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/

## Bugs

Please report bugs by creating a ticket with the GitHub issue tracker.

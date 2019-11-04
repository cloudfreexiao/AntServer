// import {Buffer} from "./buffer/buffer";
const gettype=Object.prototype.toString

const SPROTO_TARRAY = 0x80;
const CHUNK_SIZE = 1000;
const SIZEOF_LENGTH = 4;
const SIZEOF_HEADER  = 2;
const SIZEOF_FIELD  = 2;
const SIZEOF_INT64 = 8;
const SIZEOF_INT32 = 4;

const ERROR_TYPE = -3;

const ENCODE_BUFFERSIZE = 2050;

const REQUEST = 0;
const RESPONSE = 1;

/*
 * gettype.call('aaaa')输出      [object String]
 * gettype.call(2222) 输出      [object Number]
 * gettype.call(true)  输出      [object Boolean]
 * gettype.call(undefined)  输出      [object Undefined]
 * gettype.call(null)  输出   [object Null]
 * gettype.call({})   输出   [object Object]
 * gettype.call([])    输出   [object Array]
 * gettype.call(function(){})     输出   [object Function]
*/
function checktype(value, type) {
	const typestr = gettype.call(value);
	let cmp = typestr.substring(8, typestr.length - 1);
	cmp = cmp.toLowerCase();

	if (cmp == type) {
		return true;
	} else {
		return cmp;
	}
}


function isNull(val) {
	if (val === undefined || val === null) {
		return true;
	}

	return false;
}

function uint64_rshift(num, offset){
    return Math.floor(num / Math.pow(2, offset));
}

function hi_low_uint64(low, hi){
    var value = (hi & 0xFFFFFFFF) * 0x100000000 + low;
    return value;
}

function checkInteger(num, offset:number = 31) {
	let numh = uint64_rshift(num, offset);
    if (numh === 0 || numh === -1) {
    	return 4;
    } else {
    	return 8;
    }
}

function fill_size(data, data_idx, sz){
    data[data_idx] = sz & 0xff;
    data[data_idx+1] = (sz >> 8) & 0xff;
    data[data_idx+2] = (sz >> 16) & 0xff;
    data[data_idx+3] = (sz >> 24) & 0xff;
    return sz + SIZEOF_LENGTH;
}


function encode_integer(v, data, data_idx, size) {
    if (size < SIZEOF_LENGTH * 2) {
    	return -1;
    }

    data[data_idx+4] = v & 0xff;
    data[data_idx+5] = (v >> 8) & 0xff;
    data[data_idx+6] = (v >> 16) & 0xff;
    data[data_idx+7] = (v >> 24) & 0xff;
    return fill_size(data, data_idx, 4);
}

function encode_uint64(v, data, data_idx, size) {
	if (size < SIZEOF_LENGTH + SIZEOF_INT64) {
		return -1;
	}

	data[data_idx + 4] = v & 0xff;
	data[data_idx + 5] = (v >> 8) & 0xff;
	data[data_idx + 6] = (v >> 16) & 0xff;
	data[data_idx + 7] = (v >> 24) & 0xff;
	
	let hi =  uint64_rshift(v, 32);
	data[data_idx + 8] = hi & 0xff;
	data[data_idx + 9] = (hi >> 8) & 0xff;
	data[data_idx + 10] = (hi >> 16) & 0xff;
	data[data_idx + 11] = (hi >> 24) & 0xff;
	return fill_size(data, data_idx, SIZEOF_INT64);
}

function decode_uint64(data, data_idx) {
	let result = 0;

	result |= data[data_idx];
	result |= data[(data_idx+1) << 8];
	result |= data[(data_idx+1) << 16];
	result |= data[(data_idx+1) << 24];
	result |= data[(data_idx+1) << 32];
	result |= data[(data_idx+1) << 40];
	result |= data[(data_idx+1) << 48];
	result |= data[(data_idx+1) << 56];
	return result;
}


function checkvalue(args, type: string) {
	let value = args.value;
	let res = checktype(value, type);
	if (res !== true) {
		console.error("[sproto error]: .%s[%d] is not an %s (Is a %s)", args.name, args.i, type, res, value);
		return null;
	}

	return type;
}

function uint32_to_uint64(data, data_idx: number, negative: number|boolean) {
	if (negative === 0 || negative === false) { 
		data[data_idx++] = 0;
		data[data_idx++] = 0;
		data[data_idx++] = 0;
		data[data_idx++] = 0;
	} else {
		data[data_idx++] = 0xff;
		data[data_idx++] = 0xff;
		data[data_idx++] = 0xff;
		data[data_idx++] = 0xff;
	}
}


function gen_response(self, response, spindex, session) {
	return function(args) {
		self.header_tmp.type = null;
		self.header_tmp.session = session;

		let header = self.encode(self.__pack, self.header_tmp);
		if (response) {
			let content = self.encode("", args, response, spindex);
			let sz = header.length + content.length;
			return self.pack(Buffer.concat([header, content], sz));
		} else {
			return self.pack(header);
		}
	};
}

class Field {
	constructor(public name: string, public tag: number, public type: string) {

	}
}


class Stype {
	public f: Field[] = [];
	public maxn: number = 0;

	constructor(public name: string) {

	}
}

class Protocol {
	public st: Stype[] = [null, null];
	constructor(public name: string, public tag: number) {

	}
}

class Sproto {
	public t: Stype[] = [];
	public p: Protocol[] = [];
	private buffer: Buffer;
	private sz: number;
	private static sp_tb: Sproto[] = [];
	public header_tmp;

	constructor(public ctx: string, 
				public __session = [], 
				public __pack = "package", 
				public __pcatch = []) {

		ctx = this.common_filter(ctx);
		this.parse(ctx);
		// this.buffer = Buffer.allocUnsafe(4);
		this.buffer = Buffer.allocUnsafe(2048);
		this.header_tmp = {type: null, session: null};
	}

	private type_create(type, protoname?) {
		let name = type[0];
		if (name.charAt(0) === ".") {
			name = name.substr(1, name.length); // substr 去掉第一个字符的点.
		}

		let stype = new Stype(name);
		let content = type.input.replace(/.?{|}/g, "");
		let lines = content.match(/\w+\s+\-?\d+\s*:\s*\*?\w+/gi);
		let errsyntax = content.match(/[a-z]+\s*:\s*\*?[a-z]+/i)

		if (errsyntax) {
			console.error("[sproto error]: syntax error at tag number:", errsyntax[0]);
		}

		if (isNull(lines)) {
			return stype;
		}

		let maxn = lines.length;
		let offset = 8888888888;
		let offcounter = 0;
		let tags = []

		for (let i of lines) {
			let ft = i.split(/\s*(\-?\d+)?\s*:\s*/g);
			let tag = Number(ft[1]);
			let f = new Field(ft[0], tag, ft[2]);
			stype.f.push(f);

			if (tag < 0) {
				console.error("[sproto error]: syntax error at tag(%d) number less 0 in type %s", tag, protoname?protoname:name);
			}

			if (tags[tag]) {
				console.error("[sproto error]: redefine tag %d in type %s", tag, protoname?protoname:name);
			}

			if (tag - offset > 1) {
				++offcounter;
			}

			offset = tag;
			tags[tag] = true;
		}

		maxn += stype.f[0].tag + offcounter;
		stype.maxn = maxn;

		return stype;
	}

	protocol_create(protocol: string) {
		let nametag = protocol.match(/\w+\s+\-?\d+/i)[0];
		let arr = nametag.split(/\s+/);
		let name = arr[0];
		let tag = Number(arr[1]);

		if (tag < 0) {
			console.error("[sproto error]: syntax error at tag(%d) number less 0 at protocol %s", tag, name);
		}

		let proto = new Protocol(name, tag);
		this.p[name] = proto;
		this.__pcatch[tag] = proto;

		let requeststr = protocol.match(/request\s*{[^{}]*}/g);
		let responsestr = protocol.match(/response\s*{[^{}]*}/g);
		if (requeststr) {
			let req = ["request"];
			req["input"] = requeststr[0];
			proto.st[REQUEST] = this.type_create(req, name);
		}

		if (responsestr) {
			let resp = ["response"];
			resp["input"] = responsestr[0];
			proto.st[RESPONSE] = this.type_create(resp, name);
		}
	}


	private parse(text: string) {
		let types = text.match(/\.\w+[\s\n]*{[^{}]+}/ig);
		let errsyntax = text.match(/\n\w+[\s\n]*{/ig);

		if (errsyntax) {
			errsyntax.forEach(protoname	=> {  
				protoname += " ... }";
			    console.error("[sproto error]: syntax error at proto name:", protoname.replace(/\n/, ""));
			});
		}

		if (isNull(types) === false) {
			for (let i = 0; i < types.length; i++) {
				let mtype = types[i];
				let typestr = mtype.match(/\.\w+/i);
				if (typestr && typestr[0] != null) {
					let stype = this.type_create(typestr);
					this.t[stype.name] = stype;
				}
			}
		}

		let protocols = text.match(/\w+\s+\-?\d+\s*{[\n\t\s]*(request\s*{[^{}]*})?[\n\t\s]*(response\s*{[^{}]*})?[\n\t\s]*}/ig);
		if (isNull(protocols) === false) { 
			for (let i = 0; i < protocols.length; ++i) {
				this.protocol_create(protocols[i]);
			}
		}

	}

	// 注释过滤
	private common_filter(text: string) {
		return text.replace(/#.*\n/g, "\n");
	}

	private encode_integer_array(v, args, data, data_idx, size) {
		let fillflag = data_idx;
		let array_index = data_idx + 1;
		let intlen = SIZEOF_INT32;

		size -= (1 + SIZEOF_LENGTH);
		if (size < 0) {
			return -1;
		}

		for (let i = 0; i < v.length; i++) {
			args.value = v[i];
			args.i = i;
			if (checkvalue(args, "number") === null) {
				return ERROR_TYPE;
			}
			
			let value = v[i];
			let sz = checkInteger(value);

			if (sz === SIZEOF_INT32) { 
				data[array_index++] = value & 0xff;
				data[array_index++] = (value >> 8) & 0xff;
				data[array_index++] = (value >> 16) & 0xff;
				data[array_index++] = (value >> 24) & 0xff;
				if (intlen === SIZEOF_INT64) {
					uint32_to_uint64(data, array_index, value & 0x80000000);
					array_index += 4;
				}
			} else {
				if (sz != SIZEOF_INT64)
					return -1;

				if (intlen === SIZEOF_INT32) {
					size -= (SIZEOF_INT64 * (i - 1));
					if (size < 0) {
						return -1;
					}

					// 对前面 i-1 个32位的整数重新编码
					for (let j = i - 1; j >= 0; --j) {
						let start8 = data_idx + 1 + j * SIZEOF_INT64;
						let start4 = data_idx + 1 + j * SIZEOF_INT32;
						let k = start8;
						
						for (; k < start8 + 4; ++k) {
							data[k] = data[start4 + k - start8];
						}

						//根据第三位决定后4位是否全为 0 或者全 0xff
						uint32_to_uint64(data, k, data[start8 + 3] & 0x80);	
					}

					array_index = (data_idx + 1) + i * SIZEOF_INT64; //重新设置 array_index 起始位置
				}

				data[array_index++] = value & 0xff;
				data[array_index++] = (value >> 8) & 0xff;
				data[array_index++] = (value >> 16) & 0xff;
				data[array_index++] = (value >> 24) & 0xff;

				let hi =  uint64_rshift(value, 32);
				data[data_idx + 8] = hi & 0xff;
				data[data_idx + 9] = (hi >> 8) & 0xff;
				data[data_idx + 10] = (hi >> 16) & 0xff;
				data[data_idx + 11] = (hi >> 24) & 0xff;

				intlen = SIZEOF_INT64;
			}

			size -= intlen;
			if (size < 0 || size < SIZEOF_INT64) {
				return -1;
			}
		}

		if (array_index === data_idx + 1) {
			return 0;
		}

		data[fillflag] = intlen;
		return array_index - data_idx;
	}

	private encode_string_array(v, args, data, data_idx, size) {
		let start = data_idx;

		for (var i = 0; i < v.length; ++i) {
			args.value = v[i];
			args.i = i;
			if (checkvalue(args, "string") === null) {
				return ERROR_TYPE;
			}

			let tu = Buffer.from(v[i]);
			let len = tu.length;
			size -= (SIZEOF_LENGTH + len);
			if (size < 0) {
				return -1;
			}


			let sz = fill_size(data, data_idx, len);
			let pos = data_idx + SIZEOF_LENGTH;
			data.fill(tu, pos, pos + len);

			data_idx += sz;
		}

		return data_idx - start;
	}


	private encode_boolean_array(v, args, data, data_idx, size) {
		let start = data_idx;
		for (var i = 0; i < v.length; ++i) {
			args.value = v[i];
			args.i = i;
			if (checkvalue(args, "boolean") === null) {
				return ERROR_TYPE;
			}

			size -= SIZEOF_LENGTH;
			if (size < 0) {
				return -1;
			}

			data[data_idx++] = v[i] ? 1 : 0;
		}

		return data_idx - start;
	}

	private encode_object_array(v, args, data, data_idx, size) {
		let sz = 0;
		let start = data_idx;
		let total = 0;
		for (let i = 0; i < v.length; ++i) {
			size -= SIZEOF_LENGTH;
			if (size < 0) {
				return -1;
			}
			sz = this.lencode(args.type, v[i], start + SIZEOF_LENGTH, null, args.spindex);
			if (sz < 0) {
				if (sz === ERROR_TYPE) {
					return ERROR_TYPE;
				}
				return sz;
			}

			let tmpsz = fill_size(data, start, sz);
			size -= tmpsz;
			start += tmpsz;

			total += sz + SIZEOF_LENGTH;
		}

		return total;
	}

	private encode_array(v, args, data, data_idx, size) {
		let value = null;
		let sz = 0;
		size -= SIZEOF_LENGTH;

		if (size < 0) {
			return -1;
		}

		switch(args.type) {
		case "integer":
			sz = this.encode_integer_array(v, args, data, data_idx + SIZEOF_LENGTH, size);
			break;
		case "string":
			sz = this.encode_string_array(v, args, data, data_idx + SIZEOF_LENGTH, size);
			break;
		case "boolean":
			sz = this.encode_boolean_array(v, args, data, data_idx + SIZEOF_LENGTH, size);
			break;
		default: 
			sz = this.encode_object_array(v, args, data, data_idx + SIZEOF_LENGTH, size);
			break;
		}

		if (sz < 0) {
			return sz;
		}
		return fill_size(data, data_idx, sz);
	}

	encode(typeName: string, tbl: any, st?, spindex?) {
		let sz = 0;
		while(true) {
			sz = this.lencode(typeName, tbl, 0, st, spindex);
			if (sz < 0) {
				if (sz === ERROR_TYPE) {
					return;
				}

				let alloc_sz = this.buffer.length * 2;
				if (alloc_sz > 65535) {
					console.log("[sproto warning]: alloc memory more 6k");
					// return;
				}
				this.buffer = Buffer.allocUnsafe(alloc_sz);
			} else {
				break;
			}
		}

		let result = Buffer.allocUnsafe(sz);
		this.buffer.copy(result, 0, 0, result.length);
		return result;
	}

	private lencode(typename: string, tbl: any, startpoint: number, st?, spindex?) {
		let type = null;

		if (st) {
			type = st;
		} else {
			type = this.vquerytype(typename, spindex);
		}

		if (type === undefined) {
			console.error("[sproto error]: Invalid field type %s", typename, spindex);
			return ERROR_TYPE;
		}

		let header_sz = startpoint + SIZEOF_HEADER + type.maxn * SIZEOF_FIELD;
		let fieldidx = startpoint + SIZEOF_HEADER;
		let lasttag = -1;
		let tag = 0;
		let index = 0;
		let data = header_sz;
		let sumsz = this.buffer.length - startpoint - header_sz;
		if (sumsz < 0) {
			return -1;
		}

		let args = {name: null, value: null, i: 0};

		for (let f of type.f) {
			let sz = -1;
			let value = 0;
			let tu = tbl[f.name];
			let deatail_type = null;

			args.name = f.name;
			args.value = tu;

			if (isNull(tu)) {
				continue;
			}

			if (f.type.charAt(0) === "*") {
				deatail_type = checkvalue(args, "array");
				if (deatail_type === null) {
					return ERROR_TYPE;
				}
				let t = f.type.substring(1, f.type.length);

				sz = this.encode_array(tu, {type: t, name: f.name, spindex: spindex}, this.buffer, data, sumsz);
			} else {
				switch(f.type) {
				case "boolean":
					deatail_type = checkvalue(args, "boolean");
					if (deatail_type === null) {
						return ERROR_TYPE;
					}
				case "integer":
					if (deatail_type === null) {
						deatail_type = checkvalue(args, "number");
						if (deatail_type === null) {
							return ERROR_TYPE;
						}
					}
					
					sz = checkInteger(tu);
					if (sz == 4) {
						value = tu >>> 0;						
						if (value < 0x7fff) {
							value = (value + 1) * 2;
						} else {
							sz = encode_integer(value, this.buffer, data, sumsz);
							value = 0;
						}
					} else if (sz == 8) {	//value is int64
						sz = encode_uint64(tu, this.buffer, data, sumsz);
					}
					
					break;
				case "string":
					deatail_type = checkvalue(args, "string");
					if (deatail_type === null) {
						return ERROR_TYPE;
					}
				default:
					let isstring = deatail_type;
					if (deatail_type === null) {
						deatail_type = checkvalue(args, "object");
						if (deatail_type === null) {
							return ERROR_TYPE;
						}
					}

					let fsz = 0;
					if (isstring) {
						tu = Buffer.from(tu);
						if (sumsz - data - tu.length - SIZEOF_LENGTH < 0) {
							sz = -1;
							break;
						}
						fsz = tu.length;
						let value_idx = data + SIZEOF_LENGTH;
						this.buffer.fill(tu, value_idx, value_idx + fsz);
					} else {
						fsz = this.lencode(f.type, tu, data + SIZEOF_LENGTH, null, spindex);
					}
					if (fsz < 0) {
						if (fsz === ERROR_TYPE) {
							return ERROR_TYPE;
						}
						sz = -1;
					} else {
						sz = fill_size(this.buffer, data, fsz);
					}
					break;
				}
			}

			if (sz < 0) {
				if (sz === ERROR_TYPE) {
					return ERROR_TYPE;
				}
				return -1;
			}
			if (sz > 0) {
				if (value === 0) {
					data += sz;
					sumsz -= sz;
				}

				tag = f.tag - lasttag - 1;
				if (tag > 0) {
					tag = (tag - 1) * 2 + 1;
					if (tag > 0xffff)
						return -1;

					this.buffer[fieldidx++] = tag & 0xff;
					this.buffer[fieldidx++] = (tag >> 8) & 0xff;
					++index;
				}

				this.buffer[fieldidx++] = value & 0xff;
				this.buffer[fieldidx++] = (value >> 8) & 0xff;

				lasttag = f.tag;
				++index;
			}
		}

		this.buffer[startpoint + 0] = index & 0xff;
		this.buffer[startpoint + 1] = (index >> 8) & 0xff;

		let data_sz = data - header_sz;
		data = header_sz;

		if (index != type.maxn) {
			let start = startpoint + SIZEOF_HEADER + index * SIZEOF_FIELD;
			for (var i = start; i < start + data_sz; i++) {
				this.buffer[i] = this.buffer[data + i - start];
			}
		}

		return SIZEOF_HEADER + index * SIZEOF_FIELD + data_sz;
	}

	decode_array(type: string, buffer, data_idx: number, sz: number, st?, reqdecode?) {
		let result :any= [];

		switch (type) {
		case "integer":
			let len = buffer[data_idx++];
			--sz;
			if (len === SIZEOF_INT32) {
				if (sz % SIZEOF_INT32 != 0) {
					return false;
				}

				for (let i = 0; i < sz/SIZEOF_INT32; ++i) {
					result[i] = this.todword(buffer, data_idx);
					data_idx += SIZEOF_INT32;
				}
			} else if (len === SIZEOF_INT64) {
				if (sz % SIZEOF_INT64 !== 0) {
					return false;
				}

				for (let i = 0; i < sz/SIZEOF_INT64; ++i) {
					let	low = this.todword(buffer, data_idx, true);
					let	hi = this.todword(buffer, data_idx + SIZEOF_INT32, true);

					result[i] = hi_low_uint64(low, hi);
					data_idx += SIZEOF_INT64;
				}	
			} else {
				result = false;
			}
			break;
		case "string":
			let i = 0;
			for (;;) {
				sz -= SIZEOF_LENGTH;
				let len = this.todword(buffer, data_idx);
				data_idx += SIZEOF_LENGTH;
				sz -= len;

				result[i++] = buffer.toString("utf8", data_idx, data_idx + len);

				data_idx += len;
				if (sz == 0) {
					break;
				} else if (sz < 0) {
					return false;
				}
			}
			break;
		case "boolean":
			for (let i = 0; i < sz; ++i) {
				result[i] = buffer[data_idx + i] === 0 ? false : true;
			}
			break;
		default:
			if (sz === 0) {
				return result;
			}else if (sz < 0) {
				return false;
			}

			let j = 0;
			for (;;) {
				sz -= SIZEOF_LENGTH;
				let len = this.todword(buffer, data_idx);
				data_idx += SIZEOF_LENGTH;
				result[j] = {};

				this.ldecode(type, buffer, data_idx, result[j++], null, reqdecode);
				data_idx += len;
				sz -= len;

				if (sz == 0) {
					break;
				} else if (sz < 0) {
					return false;
				}
			}

			break;
		}

		return result;
	}

	decode(typename: string, buffer: Buffer) {
		let result = {};
		let sz = this.ldecode(typename, buffer, 0, result);
		if (sz < 0) {
			console.error("[sproto error]: decode failed");
			return;
		}
		return result;
	}

	private ldecode(typename: string, buffer: Buffer, startpoint:number, result: object, st?, reqdecode?) {
		let fn = this.toword(buffer, startpoint);
		let size = SIZEOF_HEADER;

		let field_idx = startpoint + SIZEOF_HEADER;
		let data_idx = startpoint + SIZEOF_HEADER + fn * SIZEOF_FIELD;
		let tag = -1;
		let args = {name: null, type: null};

		for (var i = 0; i < fn; ++i) {
			++tag;

			let sz = 0;
			let value = this.toword(buffer, field_idx);
			field_idx += SIZEOF_FIELD;
			size += SIZEOF_FIELD;

			if ((value & 1) !== 0) {
				tag += (value >> 1);
				continue;
			}

			value = (value>>1) - 1;
			let f = this.findtag(typename, tag, st, reqdecode);
			if (f === null) {
				continue;
			}

			let currentdata_idx = data_idx;

			if (value < 0) {
				sz = this.todword(buffer, currentdata_idx);
				currentdata_idx += SIZEOF_LENGTH;
				data_idx = currentdata_idx + sz;
				size += SIZEOF_LENGTH + sz;

				if (f.type.charAt(0) === '*') {
					let array_res :any = [];
					if (sz > 0) {
						let t = f.type.substring(1, f.type.length);
						array_res = this.decode_array(t, buffer, currentdata_idx, sz, st, reqdecode);
						if (array_res === false) {
							console.error("[sproto error]: decode array filed(%s) failed", f.name);
							return -1;
						}
					}
					result[f.name] = array_res;
				} else {
					switch (f.type) {
					case "string":
						result[f.name] = buffer.toString("utf8", currentdata_idx, currentdata_idx + sz);	
						break;
					case "integer":
						let low = this.todword(buffer, currentdata_idx);
						let hi = 0;
						if (sz === SIZEOF_INT64) {
							low = this.todword(buffer, currentdata_idx, true);
							hi = this.todword(buffer, currentdata_idx + SIZEOF_INT32, true);
						} else if (sz !== SIZEOF_INT32) {
							return -1;
						}

						result[f.name] = hi_low_uint64(low, hi);
						break;
					default:
						let subres = {};
						let tmpsz = this.ldecode(f.type, buffer, currentdata_idx, subres, null, reqdecode);
						if (tmpsz < 0) {
							return tmpsz;
						}
						size += tmpsz;
						result[f.name] = subres;
						break;
					}
				}
			} else if (f.type !== "integer" && f.type !== "boolean"){ // value>=0，必须是 integer 或者 boolean，所以要先判断 f.type类型
				console.error("[sproto error]: field(%s) type:", f.name, f.type);
				return -1;
			} else {	// value >= 0
				if (f.type === "boolean") {
					result[f.name] = value !== 0 ? true : false;
				} else {
					result[f.name] = value;
				}
			}
		}

		return size;
	}

	pencode(typename: string, tbl: object) {
		let buffer = this.encode(typename, tbl);
		return this.pack(buffer);
	}

	pdecode(typename: string, buffer) {
		return this.decode(typename, this.unpack(buffer));
	}

	pack_seg(srcbuffer, srcidx, dstbuffer, dstidx, n) {
		let header = dstidx++;
		let notzero = 0;
		let bits = 0;
		
		for (var i = 0; i < 8; ++i) {
			if(srcbuffer[srcidx + i] !== 0) {
				dstbuffer[dstidx++] = srcbuffer[srcidx + i];
				bits |= (1 << i);
				++notzero;
			}
		}

		if ((notzero === 6 || notzero === 7) && n > 0) {
			notzero = 8;
		}

		if (notzero === 8) {
			if (n > 0) {
				return 8;
			}
			return 10;
		}

		dstbuffer[header] = bits;
		return notzero + 1;
	}

	write_ff(buffer, ff_srcstart, dstbuffer, ff_desstart, n) {
		let i;
		let align8_n = (n + 7) & (~7); //8的倍数
		dstbuffer[ff_desstart] = 0xff;
		dstbuffer[ff_desstart + 1] = align8_n / 8 - 1;

		let start = ff_desstart + 2;
		let str = "";

		for (let i = start; i < start + n; ++i) {
			dstbuffer[i] = buffer[ff_srcstart + i - start];
			str += dstbuffer.toString("hex", i, i + 1) + " ";
		}

		start += n;
		for(let i = 0; i < align8_n - n; ++i){
			dstbuffer[start + i] = 0;
		}
	}
 
	pack(buffer:Buffer) {
		const srcsz = buffer.length;
		let dstsz = (srcsz + 2047) / 2048 * 2 + srcsz + 2;

		let dstbuffer = Buffer.allocUnsafe(dstsz);
		let tmp = Buffer.allocUnsafe(8);
		let dstidx = 0;
		let srcidx;
		let ff_n = 0;
		let ff_srcstart = -1;
		let ff_desstart = -1;
		let ff_buffer;

		for (let i = 0; i < srcsz; i += 8) {
			srcidx = i;

			let n = 0;
			let padding = i + 8 - srcsz;
			if (padding > 0) {
				let data_end = 8 - padding

				for (let j = 0; j < 8; ++j) {
					if (j < data_end) {
						tmp[j] = buffer[i + j];
						continue;
					}
					tmp[j] = 0;
				}

				buffer = tmp;
				srcidx = 0;
			}

			n = this.pack_seg(buffer, srcidx, dstbuffer, dstidx, ff_n);
			dstsz -= n;

			if (n === 10) {
				ff_srcstart = srcidx;
				ff_desstart = dstidx;
				ff_buffer = buffer;
				ff_n = 1;
			} else if (n === 8 && ff_n > 0) {
				++ff_n;
				if (ff_n === 256) {
					if (dstsz >= 0) {
						this.write_ff(ff_buffer, ff_srcstart, dstbuffer, ff_desstart, 256*8);
					}
					ff_n = 0;
				}
			} else {
				if (ff_n > 0) {
					if (dstsz >= 0) {
						this.write_ff(ff_buffer, ff_srcstart, dstbuffer, ff_desstart, ff_n*8);
					}
					ff_n = 0;
				}
			}

			dstidx += n;
		}

		if(dstsz >= 0){
			if(ff_n === 1) {
				this.write_ff(ff_buffer, ff_srcstart, dstbuffer, ff_desstart, 8);
			}
			else if (ff_n > 1) {
				this.write_ff(ff_buffer, ff_srcstart, dstbuffer, ff_desstart, srcsz - ff_srcstart);
			}
		}

		return dstbuffer.slice(0, dstidx);
	}

	unpack(buffer: Buffer) {
		// let osz = ENCODE_BUFFERSIZE;
		let osz = buffer.length * 2;
		let outbuffer = Buffer.allocUnsafe(osz);
		let sz = this.lunpack(buffer, outbuffer);

		if (sz < 0) {
			console.error("[sproto error]: Invalid unpack stream");
			return null;
		} 

		if (sz > osz) {
			do {
				osz *= 2;
				outbuffer = Buffer.allocUnsafe(osz);
			} while (sz > osz);

			sz = this.lunpack(buffer, outbuffer);
			if (sz < 0) {
				console.error("[sproto error]: Invalid unpack stream");
				return null;
			}
		}

		return outbuffer.slice(0, sz);
	}

	lunpack(buffer: Buffer, outbuffer: Buffer) {
		let srcidx = 0;
		let outidx = 0;

		let srcsz = buffer.length;
		let outsz = outbuffer.length;

		while (srcsz > 0) {
			let bits = buffer[srcidx++];
			--srcsz;

			if (bits === 0xff) {
				let n = (buffer[srcidx++] + 1) * 8;
				--srcsz;

				if (srcsz < n)
					return -1;

				if (outsz - outidx > n) {
					for (let j = 0; j < n; ++j) {
						outbuffer[outidx++] = buffer[srcidx++];
					}
				}
				srcsz -= n;

			} else {
				for (let i = 0; i < 8; ++i) {
					if ((bits & 1) === 1) {
						if (srcsz < 0) {
							return -1;
						}
						if (outidx < outsz) {
							outbuffer[outidx] = buffer[srcidx];
						}
						--srcsz;
						++outidx;
						++srcidx;
					} else {
						if (outidx < outsz) {
							outbuffer[outidx] = 0;
						} else {
							return outidx + 1;
						}
						++outidx;
					}
					bits >>>= 1;
				}
			}
		}

		return outidx;
		
	}

	private toword(p, pos) {
		return p[pos] | p[pos + 1]<<8;
	}

	private todword(p, pos, uint = false) {
		let num = p[pos] | p[pos + 1] << 8 | p[pos + 2] << 16 | p[pos + 3] << 24;
		if (uint) {
			num = num >>> 0;
		}

		return num;
	}

	private querytype(name: string) {
		return this.t[name];
	}

	private vquerytype(name: string, reqdecode?) {
		if (isNull(reqdecode)) {
			return this.t[name];
		} else {
			let sp = Sproto.sp_tb[reqdecode];
			return sp.t[name];
		}
	}

	private queryprotocol(name: string) {
		return this.p[name];
	}

	private findtag(typename: string, tag: number, st?, reqdecode?) {
		let type = null;
		if (!isNull(reqdecode) && isNull(st)) {
			let sp = Sproto.sp_tb[reqdecode];
			type = sp.t[typename];
		} else {
			if (st) {
				type = st;
			} else {
				type = this.querytype(typename);
			}
		}

		for (let f of type.f) {
			if (tag === f.tag) {
				return f;
			}
		}

		return null;
	}

	host(sp: Sproto) {
		Sproto.sp_tb.push(sp);
		this.__pcatch = null;
	}

	attach() {
		return function (name, args, session?) {
			let p = this.queryprotocol(name);
			if (isNull(p)) {
				console.error("[sproto error]: can't found ", name);
				return ;
			}
			this.header_tmp.type = p.tag;
			this.header_tmp.session = session;

			let header = this.encode(this.__pack, this.header_tmp);

			if (session) {
				this.__session[session] = p.st[RESPONSE] || true;
			}

			if (p.st[REQUEST]) {
				let content = this.encode(p.st[REQUEST].name, args, p.st[REQUEST]);
				let sz = header.length + content.length;
				return this.pack(Buffer.concat([header, content], sz));
			} else {
				return this.pack(header);
			}
		}.bind(this);
	}

	dispatch(buffer: Buffer, spindex: number = 0) {
		let bin = this.unpack(buffer);
		this.header_tmp.type = null;
		this.header_tmp.session = null;

		let header = this.header_tmp;
		let sz = this.ldecode(this.__pack, bin, 0, this.header_tmp);
		if (sz < 0) {
			console.error("[sproto error]: decode failed");
			return;
		}
		if (header.type) {
			// request
			let result = {};
			let p = null;
			if (this.__pcatch === null) {
				p = Sproto.sp_tb[spindex].__pcatch[header.type];
			} else {
				p = this.__pcatch[header.type];
			}

			if (p && p.st[REQUEST]) {
				let err = this.ldecode(p.st[REQUEST].name, bin, sz, result, p.st[REQUEST], spindex);
				if (err < 0) {
					console.error("[sproto error]: decode failed");
					return;
				}
			} else {
				console.error("[sproto error]: can't find protocol by tag:", header.type);
			}
			
			let session = this.header_tmp.session;
			if (session) {
				return {replay: "REQUEST", name: p.name, result: result, response: gen_response(this, p.st[RESPONSE], spindex, session).bind(this)};
			} else {
				return {replay: "REQUEST", name: p.name, result: result, response: null};
			}

		} else {
			// response
			let session = this.header_tmp.session;
			if (isNull(session)) {
				console.error("[sproto error]: session not found");
				return;
			}

			let response = this.__session[session];
			if (isNull(response)) {
				console.error("[sproto error]: Unknown session", session);
				return;
			}

			this.__session[session] = null;
			if (response === true) {
				return {replay: "RESPONSE", session: session, result: null};
			} else {
				let result = {};
				let err  = this.ldecode(response.name, bin, sz, result, response);
				if (err < 0) {
					console.error("[sproto error]: decode failed");
					return;
				}
				return {replay: "RESPONSE", session: session, result: result};
			}
		}
	}
} 

export { Sproto };






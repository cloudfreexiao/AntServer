using System;
using System.Text;
using System.Collections.Generic;

namespace Sproto {
	public class SprotoCodec {
		private const UInt32 SIZEOF_LENGTH = 4;
		private const UInt32 SIZEOF_HEADER = 2;
		private const UInt32 SIZEOF_FIELD = 2;


		public SprotoStream Encode (SprotoMgr sprotomgr,SprotoObject obj,SprotoStream writer=null) {
			if (null == writer) {
				writer = new SprotoStream();
			}
			string typename = obj.type;
			if (SprotoHelper.IsBuildInType(typename))
				SprotoHelper.Error("[SprotoCodec.Encode] expect a 'non-buildin-type sprotoobj' got '{0}'",typename);
			SprotoType type = sprotomgr.GetType(typename);
			if (null == type)
				SprotoHelper.Error("[SprotoCodec.Encode] occur a unknow-type '{0}'",typename);

			this.EncodeSprotoObject(sprotomgr,type,obj,writer);
			return writer;
		}

		public SprotoObject Decode (SprotoMgr sprotomgr,string typename,SprotoStream reader) {
			if (SprotoHelper.IsBuildInType(typename))
				SprotoHelper.Error("[SprotoCodec.Decode] expect a 'non-buildin-type' got '{0}'",typename);
			SprotoType type = sprotomgr.GetType(typename);
			if (null == type)
				SprotoHelper.Error("[SprotoCodec.Decode] occur a unknow-type '{0}'",typename);
			SprotoObject obj = this.DecodeSprotoObject(sprotomgr,type,reader);
			return obj;
		}

		private UInt32 EncodeSprotoObject (SprotoMgr sprotomgr,SprotoType type,SprotoObject obj,SprotoStream writer) {
			// encode header part
			List<UInt16> tags = new List<UInt16>(type.tagfields.Keys);
			tags.Sort();
			UInt16 fieldnum = 0;
			Int16 lasttag = -1;
			int fieldnum_pos = writer.Position;
			writer.Seek(SprotoCodec.SIZEOF_FIELD,SprotoStream.SEEK_CUR);
			List<UInt16> data_tags = new List<UInt16>();
			for (int i = 0; i < tags.Count; i++) {
				UInt16 tag = tags[i];
				SprotoField field = type.GetField(tag);
				SprotoObject fieldobj = obj.Get(field.name);
				if (fieldobj != null) {
					UInt16 skiptag = (UInt16)(tag - lasttag);
					//Console.WriteLine("skiptag: tag={0},lasttag={1},skiptag={2}",tag,lasttag,skiptag);
					lasttag = (Int16)tag;
					if (skiptag > 1) {
						skiptag = (UInt16)((skiptag-1)*2-1);
						this.WriteTag(writer,skiptag);
						fieldnum++;
					}
					fieldnum++;
					bool encode_in_header = false;
					if (!field.is_array) {
						if (field.type == "integer") {
							Int64 integer;
							if (field.digit == 0) {
								integer = (Int64)fieldobj.val;
							} else {
								integer = (Int64)(Math.Round((double)fieldobj.val * MathPow(10,field.digit)));
							}
							if (this.IsSmallInteger(integer)) {
								encode_in_header = true;
								UInt16 number = (UInt16)((integer+1)*2);
								this.WriteTag(writer,number);
							}
						} else if (field.type == "boolean") {
							encode_in_header = true;
							bool ok = (bool)fieldobj.val;
							UInt16 integer = (UInt16)(ok ? 1 : 0);
							UInt16 number = (UInt16)((integer+1)*2);
							this.WriteTag(writer,number);
						}
					}
					if (!encode_in_header) {
						this.WriteTag(writer,0);
						data_tags.Add(tag);
					} else {
					}
				}
			}
			this.FillFieldNum(writer,fieldnum_pos,fieldnum);
			UInt32 size = SprotoCodec.SIZEOF_FIELD + fieldnum * SprotoCodec.SIZEOF_FIELD;
			// encode data part
			foreach (UInt16 tag in data_tags) {
				SprotoField field = type.GetField(tag);
				SprotoType fieldtype = sprotomgr.GetType(field.type);
				SprotoObject fieldobj = obj.Get(field.name);
				int fieldsize_pos = writer.Position;
				UInt32 fieldsize = 0;
				writer.Seek(SprotoCodec.SIZEOF_LENGTH,SprotoStream.SEEK_CUR);
				if (SprotoHelper.IsBuildInType(field.type)) {
					fieldsize = this.EncodeBuildInType(field,fieldobj,writer);
				} else {
					if (field.is_array) {
						if (field.key != null) {
							string keytype = fieldtype.GetField(field.key).type;
							if (keytype == "integer") {
								Dictionary<Int64,SprotoObject> dict = fieldobj.val as Dictionary<Int64,SprotoObject>;
								fieldsize = this.EncodeSprotoObjectDict<Int64>(sprotomgr,dict,field,writer);
							} else if (keytype == "string") {
								Dictionary<string,SprotoObject> dict = fieldobj.val as Dictionary<string,SprotoObject>;
								fieldsize = this.EncodeSprotoObjectDict<string>(sprotomgr,dict,field,writer);
							} else if (keytype == "boolean") {
								Dictionary<bool,SprotoObject> dict = fieldobj.val as Dictionary<bool,SprotoObject>;
								fieldsize = this.EncodeSprotoObjectDict<bool>(sprotomgr,dict,field,writer);
							} else {
								SprotoHelper.Error("[SprotoCodec.EncodeSprotoObject] keytype expect  'integer/boolean/string' got '{0}'",keytype);
							}
						} else {
							List<SprotoObject> list = fieldobj.val as List<SprotoObject>;
							fieldsize = this.EncodeSprotoObjectList(sprotomgr,list,writer);
						}
					} else {
						fieldsize = this.EncodeSprotoObject(sprotomgr,fieldtype,fieldobj,writer);
					}
				}
				this.FillSize(writer,fieldsize_pos,fieldsize);
				size += (fieldsize + SprotoCodec.SIZEOF_LENGTH);
			}
			return size;
		}

		private SprotoObject DecodeSprotoObject (SprotoMgr sprotomgr,SprotoType type,SprotoStream reader) {
			SprotoObject obj = sprotomgr.NewSprotoObject(type.name);
			// decode header part
			UInt16 fieldnum = this.ReadUInt16(reader);
			List<UInt16> data_tags = new List<UInt16>();
			UInt16 curtag = 0;
			for (UInt16 i = 0; i < fieldnum; i++) {
				UInt16 tag = this.ReadUInt16(reader);
				if (tag == 0) {
					data_tags.Add(curtag);
					curtag++;
				} else if ( 0 == (tag & 1)) { // even
					UInt16 val = (UInt16)((tag / 2) - 1);
					SprotoField field = type.GetField(curtag);
					if (field != null) {	// for protocol version compatibility
						if (field.type == "integer") {
							if (0 == field.digit) {
								Int64 number = (Int64)(val);
								obj.Set(field.name,number);
							} else {
								double number = (double)val / MathPow(10,field.digit);
								obj.Set(field.name,number);
							}
						} else if (field.type == "boolean") {
							if (!(val == 0 || val == 1))
								SprotoHelper.Error("[SprotoCodec.DecodeSprotoObject] type={0},field={1},boolean type expect value '0/1' got '{2}'",type.name,curtag,val);
							bool ok = (val == 0) ? false : true;
							obj.Set(field.name,ok);
						} else {
							SprotoHelper.Error("[SprotoCodec.DecodeSprotoObject] type={0},field={1},expect type 'integer/boolean' got '{2}'",type.name,curtag,field.type);
						}
					}
					curtag++;
				} else {					  // odd
					curtag += (UInt16)((tag + 1) / 2);
				}
			}
			// decode data part
			foreach (UInt16 tag in data_tags) {
				SprotoField field = type.GetField(tag);
				if (field != null) {
					object fieldobj = null;
					if (SprotoHelper.IsBuildInType(field.type)) {
						fieldobj = this.DecodeBuildInType(field,reader);
					} else {
						SprotoType fieldtype = sprotomgr.GetType(field.type);
						if (field.is_array) {
							if (field.key != null) {
								string keytype = fieldtype.GetField(field.key).type;
								if (keytype == "integer") {
									fieldobj = this.DecodeSprotoObjectDict<Int64>(sprotomgr,fieldtype,field,reader);
								} else if (keytype == "string") {
									fieldobj = this.DecodeSprotoObjectDict<string>(sprotomgr,fieldtype,field,reader);
								} else if (keytype == "boolean") {

									fieldobj = this.DecodeSprotoObjectDict<bool>(sprotomgr,fieldtype,field,reader);
								} else {
									SprotoHelper.Error("[SprotoCodec.DecodeSprotoObject] keytype expect  'integer/boolean/string' got '{0}'",keytype);
								}
							} else {
								fieldobj = this.DecodeSprotoObjectList(sprotomgr,fieldtype,reader);
							}
						} else {
							this.ReadUInt32(reader);
							fieldobj = this.DecodeSprotoObject(sprotomgr,fieldtype,reader);
						}
					}
					obj.Set(field.name,fieldobj);
				} else {
					// for protocol version compatibility
					UInt32 fieldsize = this.ReadUInt32(reader);
					this.IgnoreByte(reader,fieldsize);
				}
			}
			return obj;
		}

		private void WriteUInt16(SprotoStream writer,UInt16 v) {
			//Console.WriteLine("WriteUInt16: {0}",v);
			writer.WriteByte((byte)(v & 0xff));
			writer.WriteByte((byte)((v >> 8) & 0xff));
		}

		private void WriteUInt32(SprotoStream writer,UInt32 v) {
			//Console.WriteLine("WriteUInt32: {0}",v);
			writer.WriteByte((byte)(v & 0xff));
			writer.WriteByte((byte)((v >> 8) & 0xff));
			writer.WriteByte((byte)((v >> 16) & 0xff));
			writer.WriteByte((byte)((v >> 24) & 0xff));
		}

		private void WriteUInt64(SprotoStream writer,UInt64 v) {
			//Console.WriteLine("WriteUInt64: {0}",v);
			writer.WriteByte((byte)(v & 0xff));
			writer.WriteByte((byte)((v >> 8) & 0xff));
			writer.WriteByte((byte)((v >> 16) & 0xff));
			writer.WriteByte((byte)((v >> 24) & 0xff));
			writer.WriteByte((byte)((v >> 32) & 0xff));
			writer.WriteByte((byte)((v >> 40) & 0xff));
			writer.WriteByte((byte)((v >> 48) & 0xff));
			writer.WriteByte((byte)((v >> 56) & 0xff));
		}

		private UInt16 ReadUInt16(SprotoStream reader) {
			// little-endian
			UInt16 number;
			int len = 2;
			byte[] bytes = new byte[len];
			for (int i = 0; i < len; i++) {
				bytes[i] = reader.ReadByte();
			}
			number = BitConverter.ToUInt16(bytes,0);
			//Console.WriteLine("ReadUInt16: {0}",number);
			return number;
		}

		private UInt32 PeekUInt32 (SprotoStream reader) {
			UInt32 number;
			int len = 4;
			byte[] bytes = new byte[len];
			for (int i = 0; i < len; i++) {
				bytes[i] = reader.Buffer[reader.Position+i];
			}
			number = BitConverter.ToUInt32(bytes,0);
			//Console.WriteLine("PeekUInt32: {0}",number);
			return number;
		}

		private UInt32 ReadUInt32(SprotoStream reader) {
			UInt32 number;
			int len = 4;
			byte[] bytes = new byte[len];
			for (int i = 0; i < len; i++) {
				bytes[i] = reader.ReadByte();
			}
			number = BitConverter.ToUInt32(bytes,0);
			//Console.WriteLine("ReadUInt32: {0}",number);
			return number;
		}

		private UInt64 ReadUInt64(SprotoStream reader) {
			UInt64 number;
			int len = 8;
			byte[] bytes = new byte[len];
			for (int i = 0; i < len; i++) {
				bytes[i] = reader.ReadByte();
			}
			number = BitConverter.ToUInt64(bytes,0);
			//Console.WriteLine("ReadUInt64: {0}",number);
			return number;
		}

		private UInt32 EncodeBuildInType(SprotoField field,SprotoObject fieldobj,SprotoStream writer) {
			UInt32 size = 0;
			switch (field.type) {
				case "integer":
					if (field.is_array) {
						if (field.digit == 0) {
							List<Int64> list = fieldobj.val as List<Int64>;
							size = this.EncodeIntegerList(list,writer);
						} else {
							List<double> double_list = fieldobj.val as List<double>;
							List<Int64> list = new List<Int64>();
							double_list.ForEach(v => list.Add((Int64)(Math.Round(v*MathPow(10,field.digit)))));
							size = this.EncodeIntegerList(list,writer);
						}
					} else {
						Int64 val;
						if (field.digit == 0) {
							val = (Int64)fieldobj.val;
						} else {
							val = (Int64)(Math.Round((double)fieldobj.val * MathPow(10,field.digit)));
						}
						size = this.EncodeInteger(val,writer);
					}
					break;
				case "boolean":
					if (field.is_array) {
						List<bool> list = fieldobj.val as List<bool>;
						size = this.EncodeBooleanList(list,writer);
					} else {
						SprotoHelper.Error("[SprotoCodec.EncodeBuildInType] 'boolean' should encode in header part");
						//bool val = (bool)fieldobj.val;
						//return this.EncodeBoolean(val,writer);
					}
					break;
				case "string":
					if (field.is_array) {
						List<string> list = fieldobj.val as List<string>;
						size = this.EncodeStringList(list,writer);
					} else {
						string val = fieldobj.val as string;
						size = this.EncodeString(val,writer);
					}
					break;
				case "binary":
					if (field.is_array) {
						List<byte[]> list = fieldobj.val as List<byte[]>;
						size = this.EncodeBinaryList(list,writer);
					} else {
						byte[] val = fieldobj.val as byte[];
						size = this.EncodeBinary(val,writer);
					}
					break;
				default:
					SprotoHelper.Error("[SprotoCodec.EncodeBuildInType] invalid buildin-type '{0}'",field.type);
					break;
			}
			return size;
		}

		// return 4 or 8
		private UInt32 RealSizeOfInteger(Int64 integer) {
			Int64 vh = integer >> 31;
			UInt32 sizeof_uint32 = sizeof(UInt32);
			UInt32 sizeof_uint64 = sizeof(UInt64);
			UInt32 sz = (vh == 0 || vh == -1) ? (sizeof_uint32): (sizeof_uint64);
			return sz;
		}

		private bool IsSmallInteger(Int64 integer) {
			UInt32 sizeof_uint32 = sizeof(UInt32);
			UInt32 sizeof_integer = this.RealSizeOfInteger(integer);
			if (sizeof_integer == sizeof_uint32) {
				UInt32 number = (UInt32)integer;
				if (number < 0x7fff) {
					return true;
				}
			}
			return false;
		}

		private void WriteTag (SprotoStream writer,UInt16 tag) {
			//Console.WriteLine("*WriteTag: {0}",tag);
			this.WriteUInt16(writer,tag);
		}

		private static Int64 MathPow(int v ,UInt16 digit) {
			return (Int64)Math.Pow(v,digit);
		}

		private void FillFieldNum (SprotoStream writer,int pos,UInt16 fieldnum) {
			//Console.WriteLine("*FillFieldNum: pos={0},fieldnum={1}",pos,fieldnum);
			int curpos = writer.Position;
			writer.Seek(pos,SprotoStream.SEEK_BEGIN);
			this.WriteUInt16(writer,fieldnum);
			writer.Seek(curpos,SprotoStream.SEEK_BEGIN);
		}

		private void FillSize (SprotoStream writer,int pos,UInt32 size) {
			//Console.WriteLine("*FillSize: pos={0},size={1}",pos,size);
			int curpos = writer.Position;
			writer.Seek(pos,SprotoStream.SEEK_BEGIN);
			this.WriteUInt32(writer,size);
			writer.Seek(curpos,SprotoStream.SEEK_BEGIN);
		}

		private UInt32 EncodeInteger (Int64 integer,SprotoStream writer) {
			UInt32 sizeof_uint32 = sizeof(UInt32);
			UInt32 sizeof_integer = this.RealSizeOfInteger(integer);
			if (sizeof_integer == sizeof_uint32) {
				UInt32 number = (UInt32)integer;
				this.WriteUInt32(writer,number);
			} else {
				UInt64 number = (UInt64)integer;
				this.WriteUInt64(writer,number);
			}
			return sizeof_integer;
		}

		private UInt32 EncodeBoolean (bool ok,SprotoStream writer) {
			Int64 integer = (ok)?(1):(0);
			writer.WriteByte(Convert.ToByte(integer));
			return 1;
		}

		private UInt32 EncodeString (string str,SprotoStream writer) {
			byte[] bytes = Encoding.UTF8.GetBytes(str);
			return this.EncodeBinary(bytes,writer);
		}

		private UInt32 EncodeBinary (byte[] bytes,SprotoStream writer) {
			UInt32 length = (UInt32)bytes.Length;
			writer.Write(bytes,0,bytes.Length);
			return length;
		}

		private UInt32 EncodeIntegerList(List<Int64> integer_list,SprotoStream writer) {
			UInt32 sizeof_uint32 = sizeof(UInt32);
			UInt32 sizeof_uint64 = sizeof(UInt64);
			UInt32 elem_size = sizeof_uint32;
			foreach (var integer in integer_list) {
				if (this.RealSizeOfInteger(integer) == sizeof_uint64) {
					elem_size = sizeof_uint64;
					break;
				}
			}
			UInt32 size = 1;
			writer.WriteByte(Convert.ToByte(elem_size));
			foreach (var integer in integer_list) {
				if (elem_size == sizeof_uint64) {
					UInt64 number = (UInt64)integer;
					this.WriteUInt64(writer,number);
				} else {
					UInt32 number = (UInt32)integer;
					this.WriteUInt32(writer,number);
				}
				size += elem_size;
			}
			return size;
		}

		private UInt32 EncodeBooleanList(List<bool> boolean_list,SprotoStream writer) {
			UInt32 size = (UInt32)boolean_list.Count;
			foreach (var boolean in boolean_list) {
				int integer = boolean ? 1 : 0;
				writer.WriteByte(Convert.ToByte(integer));
			}
			return size;
		}

		private UInt32 EncodeStringList(List<string> string_list,SprotoStream writer) {
			UInt32 size = 0;
			for (int i = 0; i < string_list.Count; i++) {
				string str = string_list[i];
				int length_pos = writer.Position;
				writer.Seek(SprotoCodec.SIZEOF_LENGTH,SprotoStream.SEEK_CUR);
				UInt32 length = this.EncodeString(str,writer);
				this.FillSize(writer,length_pos,length);
				size += (SprotoCodec.SIZEOF_LENGTH + length);
			}
			return size;
		}

		private UInt32 EncodeBinaryList(List<byte[]> binary_list,SprotoStream writer) {
			UInt32 size = 0;
			for (int i = 0; i < binary_list.Count; i++) {
				byte[] binary = binary_list[i];
				int length_pos = writer.Position;
				writer.Seek(SprotoCodec.SIZEOF_LENGTH,SprotoStream.SEEK_CUR);
				UInt32 length = this.EncodeBinary(binary,writer);
				this.FillSize(writer,length_pos,length);
				size += (SprotoCodec.SIZEOF_LENGTH + length);
			}
			return size;
		}


		private UInt32 EncodeSprotoObjectDict<T> (SprotoMgr sprotomgr,Dictionary<T,SprotoObject> dict,SprotoField field,SprotoStream writer) {
			UInt32 size = 0;
			List<T> keys = new List<T>(dict.Keys);
			keys.Sort(); // keep encode stable
			foreach (var key in keys) {
				SprotoObject elemobj = dict[key];
				if (elemobj.Get(field.key) == null) {
					SprotoHelper.Error("[SprotoCodec.EncodeSprotoObjectDict] exist null mainindex '{0}' in field '{1}'",field.key,field.name);
				}
				SprotoType elemtype = sprotomgr.GetType(elemobj.type);
				int elemsize_pos = writer.Position;
				writer.Seek(SprotoCodec.SIZEOF_LENGTH,SprotoStream.SEEK_CUR);
				UInt32 elemsize = this.EncodeSprotoObject(sprotomgr,elemtype,elemobj,writer);
				this.FillSize(writer,elemsize_pos,elemsize);
				size += (SprotoCodec.SIZEOF_LENGTH + elemsize);
			}
			return size;
		}

		private UInt32 EncodeSprotoObjectList (SprotoMgr sprotomgr,List<SprotoObject> list,SprotoStream writer) {
			UInt32 size = 0;
			for (int i = 0; i < list.Count; i++) {
				SprotoObject elemobj = list[i];
				SprotoType elemtype = sprotomgr.GetType(elemobj.type);
				int elemsize_pos = writer.Position;
				writer.Seek(SprotoCodec.SIZEOF_LENGTH,SprotoStream.SEEK_CUR);
				UInt32 elemsize = this.EncodeSprotoObject(sprotomgr,elemtype,elemobj,writer);
				this.FillSize(writer,elemsize_pos,elemsize);
				size += (SprotoCodec.SIZEOF_LENGTH + elemsize);
			}
			return size;
		}

		private object DecodeBuildInType (SprotoField field,SprotoStream reader) {
			object obj = null;
			switch (field.type) {
				case "integer":
					if (field.is_array) {
						List<Int64> integer_list = this.DecodeIntegerList(reader);
						if (field.digit == 0) {
							obj = integer_list;
						} else {
							List<double> double_list = new List<double>();
							integer_list.ForEach(v => double_list.Add((double)v/MathPow(10,field.digit)));
							obj = double_list;
						}
					} else {
						Int64 integer = this.DecodeInteger(reader);
						if (field.digit == 0) {
							obj = integer;
						} else {
							obj = (double)integer/MathPow(10,field.digit);
						}
					}
					break;
				case "boolean":
					if (field.is_array) {
						obj = this.DecodeBooleanList(reader);
					} else {
						SprotoHelper.Error("[SprotoCodec.DecodeBuildInType] 'boolean' should decode in header part");
						//obj = this.DecodeBoolean(reader);
					}
					break;
				case "string":
					if (field.is_array) {
						obj = this.DecodeStringList(reader);
					} else {
						obj = this.DecodeString(reader);
					}
					break;
				case "binary":
					if (field.is_array) {
						obj = this.DecodeBinaryList(reader);
					} else {
						obj = this.DecodeBinary(reader);
					}
					break;
				default:
					SprotoHelper.Error("[SprotoCodec.DecodeBuildInType] invalid buildin-type '{0}'",field.type);
					break;

			}
			return obj;
		}

		private Int64 DecodeInteger (SprotoStream reader) {
			UInt32 sizeof_integer = this.ReadUInt32(reader);
			Int64 integer;
			if (sizeof_integer == 4) {
				Int32 number = (Int32)this.ReadUInt32(reader);
				integer = (Int64)number;
			} else {
				if (sizeof_integer != 8)
					SprotoHelper.Error("[SprotoCodec.DecodeInteger] invalid integer size '{0}'",sizeof_integer);
				integer = (Int64)this.ReadUInt64(reader);
			}
			return integer;
		}

		private bool DecodeBoolean (SprotoStream reader) {
			byte b = reader.ReadByte();
			return Convert.ToBoolean(b);
		}

		private string DecodeString (SprotoStream reader) {
			byte[] bytes = this.DecodeBinary(reader);
			return Encoding.UTF8.GetString(bytes);
		}

		private byte[] DecodeBinary (SprotoStream reader) {
			int size = (int)this.ReadUInt32(reader);
			byte[] bytes = new byte[size];
			reader.Read(bytes,0,size);
			return bytes;
		}

		private List<Int64> DecodeIntegerList (SprotoStream reader) {
			List<Int64> list = new List<Int64>();
			UInt32 size = this.ReadUInt32(reader);
			if (size == 0) {
				return list;
			}
			UInt32 sizeof_integer = (UInt32)reader.ReadByte();
			size--;
			for (; size > 0; size=size-sizeof_integer) {
				Int64 integer;
				if (sizeof_integer == sizeof(UInt32)) {
					Int32 number = (Int32)this.ReadUInt32(reader);
					integer = (Int64)number;
				} else {
					integer = (Int64)this.ReadUInt64(reader);
				}
				list.Add(integer);
			}
			if (size != 0) {
				SprotoHelper.Error("[SprotoCodec.DecodeIntegerList] fail");
			}
			return list;
		}

		private List<bool> DecodeBooleanList (SprotoStream reader) {
			List<bool> list = new List<bool>();
			UInt32 size = this.ReadUInt32(reader);
			for (; size > 0; size--) {
				bool ok = this.DecodeBoolean(reader);
				list.Add(ok);
			}
			if (size != 0) {
				SprotoHelper.Error("[SprotoCodec.DecodeBooleanList] fail");
			}
			return list;
		}

		private List<string> DecodeStringList (SprotoStream reader) {
			List<string> list = new List<string>();
			List<byte[]> bytes_list = this.DecodeBinaryList(reader);
			for (int i = 0; i < bytes_list.Count; i++) {
				byte[] bytes = bytes_list[i];
				list.Add(Encoding.UTF8.GetString(bytes));
			}
			return list;
		}

		private List<byte[]> DecodeBinaryList (SprotoStream reader) {
			List<byte[]> list = new List<byte[]>();
			UInt32 size = this.ReadUInt32(reader);
			while (size > 0) {
				byte[] bytes = this.DecodeBinary(reader);
				UInt32 elem_size = (UInt32)(bytes.Length + SprotoCodec.SIZEOF_LENGTH);
				size = size - elem_size;
				if (size < 0)
					SprotoHelper.Error("[SprotoCodec.DecodeBinaryList] fail");
				list.Add(bytes);
			}
			if (size != 0)
				SprotoHelper.Error("[SprotoCodec.DecodeBinaryList] fail");
			return list;
		}

		private Dictionary<T,SprotoObject> DecodeSprotoObjectDict<T> (SprotoMgr sprotomgr,SprotoType type,SprotoField field,SprotoStream reader) {
			Dictionary<T,SprotoObject> dict = new Dictionary<T,SprotoObject>();
			UInt32 size= this.ReadUInt32(reader);
			while (size > 0) {
				UInt32 elem_size = this.ReadUInt32(reader);
				UInt32 need_size = elem_size + SprotoCodec.SIZEOF_LENGTH;
				size = size - need_size;
				if (size < 0)
					SprotoHelper.Error("[SprotoCodec.DecodeSprotoObjectDict] fail");
				SprotoObject elemobj = this.DecodeSprotoObject(sprotomgr,type,reader);
				SprotoObject keyobj = elemobj.Get(field.key);
				T key = (T)keyobj.val;
				dict[key] = elemobj;
			}
			if (size != 0)
				SprotoHelper.Error("[SprotoCodec.DecodeSprotoObjectDict] fail");
			return dict;
		}

		private List<SprotoObject> DecodeSprotoObjectList (SprotoMgr sprotomgr,SprotoType type,SprotoStream reader) {
			List<SprotoObject> list = new List<SprotoObject>();
			UInt32 size= this.ReadUInt32(reader);
			while (size > 0) {
				UInt32 elem_size = this.ReadUInt32(reader);
				UInt32 need_size = elem_size + SprotoCodec.SIZEOF_LENGTH;
				size = size - need_size;
				if (size < 0)
					SprotoHelper.Error("[SprotoCodec.DecodeSprotoObjectList] fail");
				SprotoObject elemobj = this.DecodeSprotoObject(sprotomgr,type,reader);
				list.Add(elemobj);
			}
			if (size != 0)
				SprotoHelper.Error("[SprotoCodec.DecodeSprotoObjectList] fail");
			return list;
		}

		private void IgnoreByte(SprotoStream reader,UInt32 size) {
			for (UInt32 i = 0; i < size; i++) {
				reader.ReadByte();
			}
		}
	}
}

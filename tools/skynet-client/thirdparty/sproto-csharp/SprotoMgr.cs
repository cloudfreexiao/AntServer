using System;
using System.Collections.Generic;

namespace Sproto {
	public class SprotoMgr {
		private SprotoCodec Codec;
		private SprotoPacker Packer;
		public Dictionary<string,SprotoProtocol> Protocols;
		public Dictionary<UInt16,SprotoProtocol> TagProtocols;
		public Dictionary<string,SprotoType> Types;

		public SprotoMgr () {
			this.Protocols = new Dictionary<string,SprotoProtocol>();
			this.TagProtocols = new Dictionary<UInt16,SprotoProtocol>();
			this.Types = new Dictionary<string,SprotoType>();
			this.Codec = new SprotoCodec();
			this.Packer = new SprotoPacker();
		}
		
		public void AddType (SprotoType type) {
			if (this.GetType(type.name) != null) {
				SprotoHelper.Error("redefined type '{0}'",type.name);
			}
			this.Types.Add(type.name,type);
		}

		public void AddProtocol (SprotoProtocol protocol) {
			if (this.Protocols.ContainsKey(protocol.name)) {
				SprotoHelper.Error("redefined protocol name '{0}' tag is '{1}'",protocol.name,protocol.tag);
			}
			if (this.TagProtocols.ContainsKey(protocol.tag)) {
				SprotoHelper.Error("redefined protocol tag '{0}' name is '{1}'",protocol.tag,protocol.name);
			}
			this.Protocols.Add(protocol.name,protocol);
			this.TagProtocols.Add(protocol.tag,protocol);
		}

		public SprotoType GetType (string name) {
			SprotoType type = null;
			if (!this.Types.TryGetValue(name,out type)) {
				return null;
			}
			return type;
		}

		public SprotoProtocol GetProtocol (string name) {
			SprotoProtocol protocol = null;
			if (!this.Protocols.TryGetValue(name,out protocol)) {
				return null;
			}
			return protocol;
		}

		public SprotoProtocol GetProtocol (UInt16 tag) {
			SprotoProtocol protocol = null;
			if (!this.TagProtocols.TryGetValue(tag,out protocol)) {
				return null;
			}
			return protocol;
		}

		private string check_type(string ptype,string fieldtype) {
			if (SprotoHelper.IsBuildInType(fieldtype))
				return fieldtype;
			string fullname = ptype + "." + fieldtype;
			if (this.GetType(fullname) != null)
				return fullname;
			// backtrace find
			List<string> list = new List<string>(ptype.Split('.'));
			list.RemoveAt(list.Count-1);
			if (list.Count > 0) {
				string pptype = String.Join(".",list.ToArray());
				return this.check_type(pptype,fieldtype);
			} else if (this.GetType(fieldtype) != null) {
				return fieldtype;
			} else {
				return null;
			}
		}

		private void flattypename() {
			List<string> keys = new List<string>(this.Types.Keys);
			foreach (string key in keys) {
				SprotoType type = this.Types[key];
				this._flattypename(type);
			}
		}

		private void _flattypename(SprotoType type) {
			foreach (var nest_type in type.nest_types.Values) {
				string fullname = String.Format("{0}.{1}",type.name,nest_type.name);
				nest_type.name = fullname;
				this.AddType(nest_type);
				this._flattypename(nest_type);
			}
			foreach (var field in type.fields.Values) {
				string fieldtype = field.type;
				string fullname = this.check_type(type.name,fieldtype);
				if (null == fullname )
					SprotoHelper.Error("undefined type '{0}' in field '{1}.{2}'",fieldtype,type.name,field.name);
				field.type = fullname;
			}
		}

		private void check_protocol() {
			Dictionary<UInt16,bool> defined_tag = new Dictionary<UInt16,bool>();
			foreach (var protocol in this.Protocols.Values) {
				UInt16 tag = protocol.tag;
				string name = protocol.name;
				string request = protocol.request;
				string response = protocol.response;
				if (defined_tag.ContainsKey(tag)) {
					SprotoHelper.Error("redefined protocol tag '{0}' at '{1}'",tag,name);
				}
				if (request != null && this.GetType(request) == null) {
					SprotoHelper.Error("undefined request type '{0}' in protocol '{1}'",request,name);

				}
				if (response != null && this.GetType(response) == null) {
					SprotoHelper.Error("undefined response type '{0}' in protocol '{1}'",response,name);
				}
				defined_tag.Add(tag,true);
			}
		}

		private void check_type () {
			foreach (var type in this.Types.Values) {
				foreach (var field in type.fields.Values) {
					if (!SprotoHelper.IsBuildInType(field.type) && (null == this.GetType(field.type))) {
						SprotoHelper.Error("undefined type '{0}' in field '{1}.{2}'",field.type,type.name,field.name);
					}
					if (field.key != null) {
						SprotoType fieldtype = this.GetType(field.type);
						if (null == fieldtype.GetField(field.key)) {
							SprotoHelper.Error("map index '{0}' cann't found in type '{1}'",field.key,field.type);
						}
					}
				}
			}
		}

		public void Check() {
			this.flattypename();
			this.check_protocol();	
			this.check_type();
		}

		// debug
		public void Dump () {
			Console.WriteLine("====protocol====");
			Console.WriteLine(this.dump_protocols(this.Protocols));
			Console.WriteLine("====type====");
			Console.WriteLine(this.dump_types(this.Types));
		}


		private string dump_protocols (Dictionary<string,SprotoProtocol> protocols) {
			List<string> list = new List<string>();
			foreach (var protocol in protocols.Values) {
				string fmt = "name={0},tag={1},request={2},response={3}";
				list.Add(String.Format(fmt,protocol.name,protocol.tag,protocol.request,protocol.response));
			}
			return String.Join("\n",list.ToArray());
		}

		private string dump_types (Dictionary<string,SprotoType> types,int level=1) {
			string space = new String(' ',level*4);
			List<string> list = new List<string>();
			foreach (var type in types.Values) {
				list.Add("name="+type.name);
				list.Add(space + "fields:");
				foreach (var field in type.fields.Values) {
					list.Add(space + String.Format("name={0},tag={1},type={2},is_array={3},key={4},decimal={5}",
								field.name,field.tag,field.type,field.is_array,field.key,field.digit));
				}
				/*
				list.Add(space + "nest_types:");
				list.Add(space + dump_types(type.nest_types,level+1));
				*/
			}
			return String.Join("\n",list.ToArray());
		}

		public SprotoObject NewSprotoObject(string typename,object val=null) {
			if (null == this.GetType(typename)) {
				SprotoHelper.Error("[SprotoMgr.NewSprotoObject] unsupport type '{0}'",typename);
			}
			SprotoObject obj = new SprotoObject();
			obj.type = typename;
			obj.val = val;
			return obj;
		}

		public SprotoStream Encode(SprotoObject obj,SprotoStream writer=null) {
			return this.Codec.Encode(this,obj,writer);
		}

		public SprotoObject Decode(string typename,SprotoStream reader) {
			return this.Codec.Decode(this,typename,reader);
		}

		public byte[] Pack(byte[] src,int start,int length,out int size,byte[] dest=null) {
			return this.Packer.Pack(src,start,length,out size,dest);
		}

		public byte[] Unpack(byte[] src,int start,int length,out int size,byte[] dest=null) {
			return this.Packer.Unpack(src,start,length,out size,dest);
		}

		public byte[] PackEncode(SprotoObject obj,out int size,SprotoStream writer=null) {
			SprotoStream stream = this.Encode(obj,writer);
			return this.Pack(stream.Buffer,0,stream.Position,out size);
		}

		public SprotoObject UnpackDecode(string typename,byte[] src,int start,int length) {
			int size = 0;
			byte[] buffer = this.Unpack(src,start,length,out size);
			SprotoStream reader = new SprotoStream();
			reader.Buffer = buffer;
			return this.Decode(typename,reader);
		}

		public SprotoRpc Attach (SprotoMgr EndPoint2Me) {
			return new SprotoRpc(this,EndPoint2Me);
		}
	}
}

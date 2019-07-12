using System;
using System.Collections.Generic;

namespace Sproto {
	public class SprotoType {
		public string name;
		public Dictionary<string,SprotoType> nest_types = new Dictionary<string,SprotoType>();
		public Dictionary<string,SprotoField> fields = new Dictionary<string,SprotoField>();
		public Dictionary<UInt16,SprotoField> tagfields = new Dictionary<UInt16,SprotoField>();

		public void AddField (SprotoField field) {
			string name = field.name;
			UInt16 tag = field.tag;
			if (this.fields.ContainsKey(name)) {
				SprotoHelper.Error("redefined field name '{0} {1}' in type '{2}'",name,tag,this.name);
			}
			if (this.tagfields.ContainsKey(tag)) {
				SprotoHelper.Error("redefined field tag '{0} {1}' in type '{2}'",name,tag,this.name);
			}
			this.fields.Add(name,field);
			this.tagfields.Add(tag,field);
		}

		public SprotoField GetField(string name) {
			if (!this.fields.ContainsKey(name))
				return null;
			return this.fields[name];
		}

		public SprotoField GetField(UInt16 tag) {
			if (!this.tagfields.ContainsKey(tag))
				return null;
			return this.tagfields[tag];
		}

		public void AddType (SprotoType type) {
			string name = type.name;
			if (this.nest_types.ContainsKey(name)) {
				SprotoHelper.Error("redefined nest_type '{0} in type '{1}",name,this.name);
			}
			this.nest_types.Add(name,type);
		}
	}
}

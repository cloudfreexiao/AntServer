using System;
using System.Text;
using System.Collections;
using System.Collections.Generic;

namespace Sproto {
	public class SprotoObject {
		public string type;
		public object val;
		private Dictionary<string,SprotoObject> fields = new Dictionary<string,SprotoObject>();
		public SprotoObject () {
			this.type = null;
			this.val = null;
		}

		public SprotoObject (object val) {
			string typename = SprotoObject.TypeOf(val);
			this.type = typename;
			this.val = val;
		}

		public bool Has(string fieldname) {
			if (this.fields.ContainsKey(fieldname))
				return true;
			return false;
		}

		public SprotoObject Get(string fieldname) {
			SprotoObject value;
			if (!this.fields.TryGetValue(fieldname,out value))
				return null;
			return value;
		}

		public void Set(string fieldname,object value) {
			if (value.GetType() == typeof(SprotoObject)) {
				SprotoObject obj = value as SprotoObject;
				if (null == obj.type) {
					SprotoHelper.Error("[SprotoObject] uninitialize");
				}
				this.fields.Add(fieldname,obj);
			} else {
				SprotoObject obj = new SprotoObject(value);
				this.fields.Add(fieldname,obj);
			}
		}

		public SprotoObject this[string fieldname] {
			get {
				return this.Get(fieldname);
			}

			set {
				this.Set(fieldname,value);
			}
		}

		private static bool isinteger(Type type) {
			/*
			// short:Int16,int:Int32
			if (type == typeof(Int16) ||
				type == typeof(Int32) ||
				type == typeof(Int64) ||
				type == typeof(UInt16) ||
				type == typeof(UInt32) ||
				type == typeof(UInt64)) {
				return true;
			}
			*/
			if (type == typeof(Int64))
				return true;
			return false;
		}
		
		private static bool isintegerlist(Type type) {
			/*	
			if (type == typeof(List<Int16>) ||
				type == typeof(List<Int32>) ||
				type == typeof(List<Int64>) ||
				type == typeof(List<UInt16>) ||
				type == typeof(List<UInt32>) ||
				type == typeof(List<UInt64>)) {
				return true;
			}
			*/
			if (type == typeof(List<Int64>))
				return true;
			return false;
		}

		public static string TypeOf (object obj) {
			string typename = "null";
			Type type = obj.GetType();
			if (type == typeof(string)) {
				typename = "string";
			} else if (type == typeof(bool)) {
				typename = "boolean";
			} else if (type == typeof(byte[])) {
				typename = "binary";
			} else if (type == typeof(double)) {
				// fixed-point number
				typename = "double";
			} else if (type == typeof(List<string>)) {
				typename = "string_list";
			} else if (type == typeof(List<bool>)) {
				typename = "boolean_list";
			} else if (type == typeof(List<byte[]>)) {
				typename = "binary_list";
			} else if (type == typeof(List<double>)) {
				typename = "double_list";
			} else if (type == typeof(List<SprotoObject>)) {
				typename = "object_list";
			} else if (type == typeof(Dictionary<Int64,SprotoObject>)) {
				typename = "integer_object_dict";
			} else if (type == typeof(Dictionary<string,SprotoObject>)) {
				typename = "string_object_dict";
			} else if (type == typeof(Dictionary<bool,SprotoObject>)) {
				typename = "boolean_object_dict";
			} else if (isinteger(type)) {
				typename = "integer";
			} else if (isintegerlist(type)) {
				typename = "integer_list";
			} else {
				SprotoHelper.Error("[SprotoObject] invalid type:{0},obj:{1}",type,obj);
			}
			return typename;
		}

		// implict convert
		public static implicit operator SprotoObject (Int64 val) {
			return new SprotoObject(val);
		}

		public static implicit operator SprotoObject (string val) {
			return new SprotoObject(val);
		}

		public static implicit operator SprotoObject (bool val) {
			return new SprotoObject(val);
		}

		public static implicit operator SprotoObject (byte[] val) {
			return new SprotoObject(val);
		}

		public static implicit operator SprotoObject (double val) {
			return new SprotoObject(val);
		}

		public static implicit operator SprotoObject (List<Int64> val) {
			return new SprotoObject(val);
		}

		public static implicit operator SprotoObject (List<string> val) {
			return new SprotoObject(val);
		}

		public static implicit operator SprotoObject (List<bool> val) {
			return new SprotoObject(val);
		}

		public static implicit operator SprotoObject (List<byte[]> val) {
			return new SprotoObject(val);
		}

		public static implicit operator SprotoObject (List<double> val) {
			return new SprotoObject(val);
		}

		public static implicit operator SprotoObject (List<SprotoObject> val) {
			return new SprotoObject(val);
		}

		public static implicit operator SprotoObject (Dictionary<Int64,SprotoObject> val) {
			return new SprotoObject(val);
		}

		public static implicit operator SprotoObject (Dictionary<string,SprotoObject> val) {
			return new SprotoObject(val);
		}

		public static implicit operator SprotoObject (Dictionary<bool,SprotoObject> val) {
			return new SprotoObject(val);
		}

		public static implicit operator Int64 (SprotoObject obj) {
			return (Int64)obj.val;
		}

		public static implicit operator bool (SprotoObject obj) {
			return (bool)obj.val;
		}

		public static implicit operator string (SprotoObject obj) {
			return obj.val as string;
		}

		public static implicit operator byte[] (SprotoObject obj) {
			return obj.val as byte[];
		}

		public static implicit operator double (SprotoObject obj) {
			return (double)obj.val;
		}

		public static implicit operator List<Int64> (SprotoObject obj) {
			return obj.val as List<Int64>;
		}

		public static implicit operator List<bool> (SprotoObject obj) {
			return obj.val as List<bool>;
		}

		public static implicit operator List<string> (SprotoObject obj) {
			return obj.val as List<string>;
		}

		public static implicit operator List<byte[]> (SprotoObject obj) {
			return obj.val as List<byte[]>;
		}

		public static implicit operator List<double> (SprotoObject obj) {
			return obj.val as List<double>;
		}

		public static implicit operator List<SprotoObject> (SprotoObject obj) {
			return obj.val as List<SprotoObject>;
		}

		public static implicit operator Dictionary<string,SprotoObject> (SprotoObject obj) {
			return obj.val as Dictionary<string,SprotoObject>;
		}

		public static implicit operator Dictionary<Int64,SprotoObject> (SprotoObject obj) {
			return obj.val as Dictionary<Int64,SprotoObject>;
		}

		public static implicit operator Dictionary<bool,SprotoObject> (SprotoObject obj) {
			return obj.val as Dictionary<bool,SprotoObject>;
		}


		// debug
		public void Dump () {
			Console.WriteLine(this.ToString());
		}

		// not support recursive SprotoObject
		public override string ToString () {
			string val;
			if (null == this.val) {
				val = null;
			} else {
				string typename = SprotoObject.TypeOf(this.val);
				if (typename == "integer" ||
					typename == "boolean" ||
					typename == "string" ||
					typename == "binary" ||
					typename == "double") {
					val = this.val.ToString();
				} else if (typename == "integer_list") {
					val = SprotoHelper.DumpList<Int64>(this.val as List<Int64>);
				} else if (typename == "boolean_list") {
					val = SprotoHelper.DumpList<bool>(this.val as List<bool>);
				} else if (typename == "string_list") {
					val = SprotoHelper.DumpList<string>(this.val as List<string>);
				} else if (typename == "binary_list") {
					val = SprotoHelper.DumpList<byte[]>(this.val as List<byte[]>);
				} else if (typename == "double_list") {
					val = SprotoHelper.DumpList<double>(this.val as List<double>);
				} else if (typename == "object_list") {
					val = SprotoHelper.DumpList<SprotoObject>(this.val as List<SprotoObject>);
				} else if (typename == "integer_object_dict") {
					val = SprotoHelper.DumpDict<Int64,SprotoObject>(this.val as Dictionary<Int64,SprotoObject>);
				} else if (typename == "string_object_dict") {
					val = SprotoHelper.DumpDict<string,SprotoObject>(this.val as Dictionary<string,SprotoObject>);
				} else if (typename == "boolean_object_dict") {
					val = SprotoHelper.DumpDict<bool,SprotoObject>(this.val as Dictionary<bool,SprotoObject>);
				} else {
					val = "unknow";
				}
			}
			string fields = SprotoHelper.DumpDict<string,SprotoObject>(this.fields);
			return "{"+String.Format("type={0},val={1},fields={2}",this.type,val,fields) + "}";
		}
	}
}

using System;
using System.Text;
using System.Collections.Generic;
using System.Diagnostics;

namespace Sproto {
	public class SprotoHelper {
		public static void Error (string fmt,params object[] args) {
			string errmsg = String.Format(fmt,args);
			throw new Exception(errmsg);
		}

		public static void Assert(bool condition,string errmsg=null) {
			if (!condition) {
				throw new Exception(errmsg);
			}
		}

		public static bool IsBuildInType(string type) {
			switch (type) {
				case "integer":
					return true;
				case "boolean":
					return true;
				case "string":
					return true;
				case "binary":
					return true;
				default:
					return false;
			}
		}

		public static string DumpList<T> (List<T> list) {
			StringBuilder sb = new StringBuilder();
			sb.Append("{");
			foreach (var item in list) {
				sb.Append(item + ",");
			}
			sb.Append("}");
			return sb.ToString();
		}

		public static string DumpDict<TKey,TValue> (Dictionary<TKey,TValue> dict) {
			StringBuilder sb = new StringBuilder();
			sb.Append("{");
			foreach (var item in dict) {
				sb.Append(String.Format("{0}={1},",item.Key,item.Value));
			}
			sb.Append("}");
			return sb.ToString();
		}

		public static string DumpBytes(byte[] bytes,int start=0,int length=0) {
			if (length == 0) {
				length = bytes.Length;
			}
			StringBuilder sb = new StringBuilder();
			sb.Append(String.Format("len: {0}\n",length));
			for (int i = 0; i < length; i++) {
				sb.Append(String.Format("{0:x2} ",bytes[start+i]));
				if ((i+1) % 8 == 0)
					sb.Append("\n");
			}
			return sb.ToString();
		}

		public static void PrintBytes(byte[] bytes,int start=0,int length=0) {
			Console.WriteLine(SprotoHelper.DumpBytes(bytes,start,length));
		}
	}
}

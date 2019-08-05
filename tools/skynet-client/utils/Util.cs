

namespace Skynet.DotNetClient.Utils
{
	using System.Collections.Generic;
	using System;
	using UnityEngine;
	using Sproto;
	
	public class Util {
		public static void DumpStream (SpStream stream) {
			string str = "";
			
			byte[] buf = new byte[16];
			int count;
			
			while ((count = stream.Read (buf, 0, buf.Length)) > 0) {
				str += DumpLine (buf, count);
			}

			Log (str);
		}
		
		private static string DumpLine (byte[] buf, int count) {
			string str = "";
			
			for (int i = 0; i < count; i++) {
				str += ((i < count) ? String.Format ("{0:X2}", buf[i]) : "  ");
				str += ((i > 0) && (i < count - 1) && ((i + 1) % 8 == 0) ? " " : " ");
			}
			str += "\n";
			
			return str;
		}
		
		public static void DumpObject (SpObject obj) {
			Log (DumpObject (obj, 0));
		}
		
		private static string DumpObject (SpObject obj, int tab) {
			string str = "";

	        if (obj != null) {
	            if (obj.IsTable ()) {
	                str = GetTab (tab) + "<table>\n";
	                foreach (KeyValuePair<object, SpObject> entry in obj.AsTable ()) {
	                    str += GetTab (tab + 1) + "<key : " + entry.Key + ">\n";
	                    str += DumpObject (entry.Value, tab + 1);
	                }
	            }
				else if (obj.Value == null) {
					str = GetTab (tab) + "<null>\n";
				}
				else {
					str = GetTab (tab) + obj.Value.ToString () + "\n";
				}
	        }
			
			return str;
		}
		
		private static string GetTab(int n) {
			string str = "";
			for (int i = 0; i < n; i++)
				str += "\t";
			return str;
		}

		public static void Log (object obj) {
			Debug.Log (obj);
		}

		public static void Assert(bool condition) {
			if (condition == false)
				throw new Exception();
		}

		public static string GetFullPath (string path) {
			return Application.dataPath +  "/" + path;
		}
		
		
		public static void DumpBytes(byte[] buffer, int offset)
		{
			string returnStr = "";
			for (int i = 0; i < offset; i++)
			{
				returnStr += buffer[i].ToString("X2");
			}
			Debug.Log("-------Begin----\n");
			Debug.Log(returnStr);
			Debug.Log("-------End----\n");
		}
	}
}

using System;
using System.Collections.Generic;
using System.Text;
using Sproto;

namespace TestSproto {
	public static class TestSprotoObject {
		public static void Run () {
			Console.WriteLine("TestSprotoObject.Run ...");
			string filename = "Test/TestAll.sproto";
			SprotoMgr sproto = SprotoParser.ParseFile(filename);
			var foobar = sproto.NewSprotoObject("foobar");
			foobar["a"] = "hello";
			foobar["b"] = 100;
			foobar["c"] = true;
			var nest = sproto.NewSprotoObject("foobar.nest");
			nest["a"] = "hello";
			nest["b"] = true;
			nest["c"] = 100;
			
			Dictionary<string,SprotoObject> nestDict = new Dictionary<string,SprotoObject>();
			nestDict.Add(nest["a"],nest);
			foobar["d"] = nestDict;
			List<string> strList = new List<string>();
			strList.Add("hello");
			strList.Add("world");
			foobar["e"] = strList;
			List<Int64> intList = new List<Int64>();
			intList.Add(1);
			intList.Add(2);
			intList.Add(3);
			foobar["f"] = intList;
			List<bool> boolList = new List<bool>();
			boolList.Add(true);
			boolList.Add(false);
			foobar["g"] = boolList;

			List<SprotoObject> foobarList = new List<SprotoObject>();
			// null foobar2
			SprotoObject foobar2 = sproto.NewSprotoObject("foobar");
			foobarList.Add(foobar2);
			foobar["h"] = foobarList;
			List<double> doubleList = new List<double>();
			doubleList.Add(1.355);
			doubleList.Add(1.354);
			foobar["i"] = doubleList;
			byte[] binary = Encoding.UTF8.GetBytes("abcdef");
			foobar["j"] = binary;
			foobar.Dump();

			SprotoHelper.Assert(foobar["a"] == "hello");
			SprotoHelper.Assert(foobar["b"] == 100);
			SprotoHelper.Assert(foobar["c"] == true);
			Dictionary<string,SprotoObject> expect_d = foobar["d"];
			SprotoHelper.Assert(expect_d.Count == 1);
			SprotoHelper.Assert(expect_d["hello"]["a"] == "hello");
			SprotoHelper.Assert(expect_d["hello"]["b"] == true);
			SprotoHelper.Assert(expect_d["hello"]["c"] == 100);
			List<string> expect_e = foobar["e"];
			SprotoHelper.Assert(expect_e.Count == 2);
			SprotoHelper.Assert(expect_e[0] == "hello");
			SprotoHelper.Assert(expect_e[1] == "world");
			List<Int64> expect_f = foobar["f"];
			SprotoHelper.Assert(expect_f.Count == 3);
			SprotoHelper.Assert(expect_f[0] == 1);
			SprotoHelper.Assert(expect_f[1] == 2);
			SprotoHelper.Assert(expect_f[2] == 3);
			List<bool> expect_g = foobar["g"];
			SprotoHelper.Assert(expect_g.Count == 2);
			SprotoHelper.Assert(expect_g[0] == true);
			SprotoHelper.Assert(expect_g[1] == false);
			List<SprotoObject> expect_h = foobar["h"];
			SprotoHelper.Assert(expect_h.Count == 1);
			SprotoHelper.Assert(expect_h[0].val == null);
			List<double> expect_i = foobar["i"];
			SprotoHelper.Assert(expect_i[0] == 1.355);
			SprotoHelper.Assert(expect_i[1] == 1.354);
			byte[] expect_j = foobar["j"];
			bool ok = true;
			for (int i = 0; i < expect_j.Length; i++) {
				if (expect_j[i] != binary[i]) {
					ok = false;
					break;
				}
			}
			SprotoHelper.Assert(ok);

			// encode/decode
			SprotoStream encode_stream = sproto.Encode(foobar);
			int length = encode_stream.Position;
			SprotoStream decode_stream = encode_stream;
			decode_stream.Seek(0,SprotoStream.SEEK_BEGIN);
			SprotoObject decode_foobar = sproto.Decode("foobar",decode_stream);
			decode_foobar.Dump();
			SprotoHelper.Assert(decode_foobar["a"] == "hello");
			SprotoHelper.Assert(decode_foobar["b"] == 100);
			SprotoHelper.Assert(decode_foobar["c"] == true);
			expect_d = decode_foobar["d"];
			SprotoHelper.Assert(expect_d.Count == 1);
			SprotoHelper.Assert(expect_d["hello"]["a"] == "hello");
			SprotoHelper.Assert(expect_d["hello"]["b"] == true);
			SprotoHelper.Assert(expect_d["hello"]["c"] == 100);
			expect_e = decode_foobar["e"];
			SprotoHelper.Assert(expect_e.Count == 2);
			SprotoHelper.Assert(expect_e[0] == "hello");
			SprotoHelper.Assert(expect_e[1] == "world");
			expect_f = decode_foobar["f"];
			SprotoHelper.Assert(expect_f.Count == 3);
			SprotoHelper.Assert(expect_f[0] == 1);
			SprotoHelper.Assert(expect_f[1] == 2);
			SprotoHelper.Assert(expect_f[2] == 3);
			expect_g = decode_foobar["g"];
			SprotoHelper.Assert(expect_g.Count == 2);
			SprotoHelper.Assert(expect_g[0] == true);
			SprotoHelper.Assert(expect_g[1] == false);
			expect_h = decode_foobar["h"];
			SprotoHelper.Assert(expect_h.Count == 1);
			SprotoHelper.Assert(expect_h[0].val == null);
			expect_i = decode_foobar["i"];
			SprotoHelper.Assert(expect_i[0] == 1.36);
			SprotoHelper.Assert(expect_i[1] == 1.35);
			expect_j = decode_foobar["j"];
			ok = true;
			for (int i = 0; i < expect_j.Length; i++) {
				if (expect_j[i] != binary[i]) {
					ok = false;
					break;
				}
			}
			SprotoHelper.Assert(ok);

			Console.WriteLine("TestSprotoObject.Run ok");
		}
	}
}

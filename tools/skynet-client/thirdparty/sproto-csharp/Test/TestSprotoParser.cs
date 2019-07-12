using System;
using System.Collections.Generic;
using System.Text;
using Sproto;
using System.IO;

namespace TestSproto {
	public static class TestSprotoParser {
		public static void Run () {
			Console.WriteLine("TestSprotoParser.Run ...");
			string filename = "Test/TestAll.sproto";
			SprotoMgr sproto = SprotoParser.ParseFile(filename);
			//sproto.Dump();
			byte[] bin = SprotoParser.DumpToBinary(sproto);
			//SprotoHelper.PrintBytes(bin,0,bin.Length);

			filename = "Test/TestAll.spb";
			SprotoMgr sproto2 = SprotoParser.ParseFromBinaryFile(filename);
			sproto2.Dump();
			byte[] bin2 = SprotoParser.DumpToBinary(sproto2);
			//SprotoHelper.PrintBytes(bin2,0,bin2.Length);
			bool ok = bin.Length == bin2.Length;
			SprotoHelper.Assert(ok);
			for (int i = 0; i < bin.Length; i++) {
				if (bin[i] != bin2[i]) {
					ok = false;
					break;
				}
			}
			SprotoHelper.Assert(ok);
			Console.WriteLine("TestSprotoParser.Run ok");
		}
	}
}

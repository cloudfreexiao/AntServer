using System;

namespace TestSproto {
	public class Program {
		static void Main (string[] args) {
			TestAll.Run();
			TestSprotoObject.Run();
			TestSprotoCodec.Run();
			TestSprotoPacker.Run();
			TestSprotoRpc.Run();
			TestSprotoParser.Run();
			SimpleExample.Run();
			SprotoBenchMark.Run();
		}
	}
}

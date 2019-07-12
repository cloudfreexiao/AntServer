using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using Sproto;

namespace TestSproto {
	public static class TestAll {
		public static void Run () {
			Console.WriteLine("TestAll.Run ...");
			string proto =
@".foobar {
	.nest {
		a 1 : string
		b 3 : boolean
		c 5 : integer
		d 6 : integer(3)
	}
	a 0 : string
	b 1 : integer
	c 2 : boolean
	d 3 : *nest(a)

	e 4 : *string
	f 5 : *integer
	g 6 : *boolean
	h 7 : *foobar
	i 8 : *integer(2)
	j 9 : binary
}
";
			SprotoMgr sprotomgr = SprotoParser.Parse(proto);
			sprotomgr.Dump();
			string filename = "Test/Person.sproto";
			SprotoMgr sprotomgr2 = SprotoParser.ParseFile(filename);
			sprotomgr2.Dump();

			Console.WriteLine("TestAll.Run ok");
		}
	}
}

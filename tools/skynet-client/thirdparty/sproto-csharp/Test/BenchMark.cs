using System;
using System.Collections.Generic;
using Sproto;

namespace TestSproto {
	public static class SprotoBenchMark {
		public static void Run () {
			string filename = "Test/BenchMark.sproto";
			SprotoMgr sprotomgr = SprotoParser.ParseFile(filename);
			SprotoObject address = sprotomgr.NewSprotoObject("AddressBook");
			SprotoObject person1 = sprotomgr.NewSprotoObject("Person");
			person1["name"] = "Alice";
			person1["id"] = 10000;
			List<SprotoObject> phones = new List<SprotoObject>();
			SprotoObject phone1 = sprotomgr.NewSprotoObject("Person.PhoneNumber");
			phone1["number"] = "123456789";
			phone1["type"] = 1;
			SprotoObject phone2 = sprotomgr.NewSprotoObject("Person.PhoneNumber");
			phone2["number"] = "87654321";
			phone2["type"] = 2;
			phones.Add(phone1);
			phones.Add(phone2);
			person1["phone"] = phones;
			SprotoObject person2 = sprotomgr.NewSprotoObject("Person");
			person2["name"] = "Bob";
			person2["id"] = 20000;
			phones = new List<SprotoObject>();
			phone1 = sprotomgr.NewSprotoObject("Person.PhoneNumber");
			phone1["number"] = "01234567890";
			phone1["type"] = 3;
			phones.Add(phone1);
			person2["phone"] = phones;
			List<SprotoObject> persons = new List<SprotoObject>();
			persons.Add(person1);
			persons.Add(person2);
			address["person"] = persons;

			int times = 1000000;
			SprotoStream writer = new SprotoStream();
			sprotomgr.Dump();
			Console.WriteLine("benchmark times: {0}",times);

			double start = SprotoBenchMark.cur_mssecond();
			for (int i = 0; i < times; i++) {
				writer.Seek(0,SprotoStream.SEEK_BEGIN); // clear stream
				writer = sprotomgr.Encode(address,writer);
			}
			double end = SprotoBenchMark.cur_mssecond();
			int size = writer.Position;
			Console.WriteLine("[Encode] total={0}ms,size={1}byte",end-start,size);

			SprotoStream reader = writer;
			start = SprotoBenchMark.cur_mssecond();
			for (int i = 0; i < times; i++) {
				reader.Seek(0,SprotoStream.SEEK_BEGIN);
				sprotomgr.Decode("AddressBook",reader);
			}
			end = SprotoBenchMark.cur_mssecond();
			Console.WriteLine("[Decode] total={0}ms",end-start);

			byte[] bin = null;
			size = 0;
			start = SprotoBenchMark.cur_mssecond();
			for (int i = 0; i < times; i++) {
				writer.Seek(0,SprotoStream.SEEK_BEGIN);
				bin = sprotomgr.PackEncode(address,out size,writer);
			}
			end = SprotoBenchMark.cur_mssecond();
			Console.WriteLine("[PackEncode] total={0}ms,size={1}byte",end-start,size);

			start = SprotoBenchMark.cur_mssecond();
			for (int i = 0; i < times; i++) {
				sprotomgr.UnpackDecode("AddressBook",bin,0,size);
			}
			end = SprotoBenchMark.cur_mssecond();
			Console.WriteLine("[UnpackDecode] total={0}ms",end-start);
		}

		public static double cur_mssecond () {
			TimeSpan ts = DateTime.Now - new DateTime(1970,1,1);
			return ts.TotalMilliseconds;
		}
	}
}

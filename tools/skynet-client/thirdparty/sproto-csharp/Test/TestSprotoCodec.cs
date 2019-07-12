using System;
using System.Collections.Generic;
using Sproto;

namespace TestSproto {
	public static class TestSprotoCodec {
		public static void Run () {
			Console.WriteLine("TestSprotoCodec.Run ...");
			// see https://github.com/cloudwu/sproto
			string filename = "Test/Person.sproto";
			SprotoMgr sproto = SprotoParser.ParseFile(filename);
			Console.WriteLine("=====example 1=====");
			SprotoObject obj = sproto.NewSprotoObject("Person");
			obj["name"] = "Alice";
			obj["age"] = 13;
			obj["marital"] = false;
			SprotoObject data = sproto.NewSprotoObject("Data");
			data["number"] = 1;
			obj["data"] = data;

			byte[] expect_bytes = {
				0x05,0x00,
				0x00,0x00,
				0x1c,0x00,
				0x02,0x00,
				0x01,0x00,	// (skip id=3)
				0x00,0x00,
				0x05,0x00,0x00,0x00,
				0x41,0x6c,0x69,0x63,0x65,
				// Data field
				0x06,0x00,0x00,0x00,
				0x02,0x00,
				0x03,0x00,
				0x04,0x00,
			};

			SprotoStream encode_stream = sproto.Encode(obj);
			int length = encode_stream.Position;
			SprotoHelper.PrintBytes(encode_stream.Buffer,0,length);
			bool ok = true;
			for (int i = 0; i < length; i++) {
				if (encode_stream.Buffer[i] != expect_bytes[i]) {
					ok = false;
					break;
				}
			}
			SprotoHelper.Assert(ok);
			SprotoStream decode_stream = encode_stream;
			decode_stream.Seek(0,SprotoStream.SEEK_BEGIN);
			Console.WriteLine("decode_stream.Position:{0}",decode_stream.Position);
			//SprotoHelper.PrintBytes(decode_stream.Buffer,0,length);
			SprotoObject decode_obj = sproto.Decode("Person",decode_stream);
			SprotoHelper.Assert(decode_stream.Position == length);
			SprotoHelper.Assert(decode_obj["name"] == "Alice");
			SprotoHelper.Assert(decode_obj["age"] == 13);
			SprotoHelper.Assert(decode_obj["marital"] == false);
			SprotoHelper.Assert(decode_obj["children"] == null);
			SprotoObject decode_data = decode_obj["data"];
			SprotoHelper.Assert(decode_data["number"] == 1);

			Console.WriteLine("=====example 2=====");
			obj = sproto.NewSprotoObject("Person");
			List<SprotoObject> children = new List<SprotoObject>();
			SprotoObject child1 = sproto.NewSprotoObject("Person");
			child1["name"] = "Alice";
			child1["age"] = 13;
			SprotoObject child2 = sproto.NewSprotoObject("Person");
			child2["name"] = "Carol";
			child2["age"] = 5;
			children.Add(child1);
			children.Add(child2);
			obj["name"] = "Bob";
			obj["age"] = 40;
			obj["children"] = children;
			expect_bytes = new byte[] {
				0x04,0x00,
				0x00,0x00,
				0x52,0x00,
				0x01,0x00,
				0x00,0x00,
				0x03,0x00,0x00,0x00,
				0x42,0x6f,0x62,
				0x26,0x00,0x00,0x00,
				0x0f,0x00,0x00,0x00,
				0x02,0x00,
				0x00,0x00,
				0x1c,0x00,
				0x05,0x00,0x00,0x00,
				0x41,0x6c,0x69,0x63,0x65,
				0x0f,0x00,0x00,0x00,
				0x02,0x00,
				0x00,0x00,
				0x0c,0x00,
				0x05,0x00,0x00,0x00,
				0x43,0x61,0x72,0x6f,0x6c,
			};
			encode_stream = sproto.Encode(obj);
			length = encode_stream.Position;
			SprotoHelper.PrintBytes(encode_stream.Buffer,0,length);
			ok = true;
			for (int i = 0; i < length; i++) {
				if (encode_stream.Buffer[i] != expect_bytes[i]) {
					ok = false;
					break;
				}
			}
			SprotoHelper.Assert(ok);
			decode_stream = encode_stream;
			decode_stream.Seek(0,SprotoStream.SEEK_BEGIN);
			Console.WriteLine("decode_stream.Position:{0}",decode_stream.Position);
			//SprotoHelper.PrintBytes(decode_stream.Buffer,0,length);
			decode_obj = sproto.Decode("Person",decode_stream);
			SprotoHelper.Assert(decode_stream.Position == length);
			SprotoHelper.Assert(decode_obj["name"] == "Bob");
			SprotoHelper.Assert(decode_obj["age"] == 40);
			SprotoHelper.Assert(decode_obj["marital"] == null);
			List<SprotoObject> decode_children = decode_obj["children"];
			SprotoHelper.Assert(decode_children != null);
			SprotoHelper.Assert(decode_children.Count == 2);
			SprotoObject decode_child1 = decode_children[0];
			SprotoObject decode_child2 = decode_children[1];
			SprotoHelper.Assert(child1["name"] == "Alice");
			SprotoHelper.Assert(child1["age"] == 13);
			SprotoHelper.Assert(child2["name"] == "Carol");
			SprotoHelper.Assert(child2["age"] == 5);

			Console.WriteLine("=====example 3=====");
			obj = sproto.NewSprotoObject("Data");
			List<Int64> numbers = new List<Int64>{1,2,3,4,5};
			obj["numbers"] = numbers;
			expect_bytes = new byte[] {
				0x01,0x00,
				0x00,0x00,
				0x15,0x00,0x00,0x00,
				0x04,
				0x01,0x00,0x00,0x00,
				0x02,0x00,0x00,0x00,
				0x03,0x00,0x00,0x00,
				0x04,0x00,0x00,0x00,
				0x05,0x00,0x00,0x00,
			};
			encode_stream = sproto.Encode(obj);
			length = encode_stream.Position;
			SprotoHelper.PrintBytes(encode_stream.Buffer,0,length);
			ok = true;
			for (int i = 0; i < length; i++) {
				if (encode_stream.Buffer[i] != expect_bytes[i]) {
					ok = false;
					break;
				}
			}
			SprotoHelper.Assert(ok);
			decode_stream = encode_stream;
			decode_stream.Seek(0,SprotoStream.SEEK_BEGIN);
			Console.WriteLine("decode_stream.Position:{0}",decode_stream.Position);
			//SprotoHelper.PrintBytes(decode_stream.Buffer,0,length);
			decode_obj = sproto.Decode("Data",decode_stream);
			SprotoHelper.Assert(decode_stream.Position == length);
			List<Int64> decode_numbers = decode_obj["numbers"];
			SprotoHelper.Assert(decode_numbers.Count == numbers.Count);
			for(int i = 0; i < decode_numbers.Count; i++) {
				SprotoHelper.Assert(numbers[i] == decode_numbers[i]);
			}


			Console.WriteLine("=====example 4=====");
			obj = sproto.NewSprotoObject("Data");
			numbers = new List<Int64>{
				(Int64)((1ul<<32)+1),
				(Int64)((1ul<<32)+2),
				(Int64)((1ul<<32)+3),
			};
			obj["numbers"] = numbers;
			expect_bytes = new byte[] {
				0x01,0x00,
				0x00,0x00,
				0x19,0x00,0x00,0x00,
				0x08,
				0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,
				0x02,0x00,0x00,0x00,0x01,0x00,0x00,0x00,
				0x03,0x00,0x00,0x00,0x01,0x00,0x00,0x00,
			};
			encode_stream = sproto.Encode(obj);
			length = encode_stream.Position;
			SprotoHelper.PrintBytes(encode_stream.Buffer,0,length);
			ok = true;
			for (int i = 0; i < length; i++) {
				if (encode_stream.Buffer[i] != expect_bytes[i]) {
					ok = false;
					break;
				}
			}
			SprotoHelper.Assert(ok);
			decode_stream = encode_stream;
			decode_stream.Seek(0,SprotoStream.SEEK_BEGIN);
			Console.WriteLine("decode_stream.Position:{0}",decode_stream.Position);
			//SprotoHelper.PrintBytes(decode_stream.Buffer,0,length);
			decode_obj = sproto.Decode("Data",decode_stream);
			SprotoHelper.Assert(decode_stream.Position == length);
			decode_numbers = decode_obj["numbers"];
			SprotoHelper.Assert(decode_numbers.Count == numbers.Count);
			for(int i = 0; i < decode_numbers.Count; i++) {
				SprotoHelper.Assert(numbers[i] == decode_numbers[i]);
			}


			Console.WriteLine("=====example 5=====");
			obj = sproto.NewSprotoObject("Data");
			List<bool> bools = new List<bool>{false,true,false};
			obj["bools"] = bools;
			expect_bytes = new byte[] {
				0x02,0x00,
				0x01,0x00,
				0x00,0x00,
				0x03,0x00,0x00,0x00,
				0x00,
				0x01,
				0x00,
			};
			encode_stream = sproto.Encode(obj);
			length = encode_stream.Position;
			SprotoHelper.PrintBytes(encode_stream.Buffer,0,length);
			ok = true;
			for (int i = 0; i < length; i++) {
				if (encode_stream.Buffer[i] != expect_bytes[i]) {
					ok = false;
					break;
				}
			}
			SprotoHelper.Assert(ok);
			decode_stream = encode_stream;
			decode_stream.Seek(0,SprotoStream.SEEK_BEGIN);
			Console.WriteLine("decode_stream.Position:{0}",decode_stream.Position);
			//SprotoHelper.PrintBytes(decode_stream.Buffer,0,length);
			decode_obj = sproto.Decode("Data",decode_stream);
			SprotoHelper.Assert(decode_stream.Position == length);
			List<bool> decode_bools = decode_obj["bools"];
			SprotoHelper.Assert(decode_bools.Count == bools.Count);
			for(int i = 0; i < decode_bools.Count; i++) {
				SprotoHelper.Assert(bools[i] == decode_bools[i]);
			}

			Console.WriteLine("=====example 6=====");
			obj = sproto.NewSprotoObject("Data");
			obj["number"] = 100000;
			obj["bignumber"] = -10000000000;
			expect_bytes = new byte[] {
				0x03,0x00,
				0x03,0x00,
				0x00,0x00,
				0x00,0x00,
				0x04,0x00,0x00,0x00,
				0xa0,0x86,0x01,0x00,
				0x08,0x00,0x00,0x00,
				0x00,0x1c,0xf4,0xab,0xfd,0xff,0xff,0xff,
			};
			encode_stream = sproto.Encode(obj);
			length = encode_stream.Position;
			SprotoHelper.PrintBytes(encode_stream.Buffer,0,length);
			ok = true;
			for (int i = 0; i < length; i++) {
				if (encode_stream.Buffer[i] != expect_bytes[i]) {
					ok = false;
					break;
				}
			}
			SprotoHelper.Assert(ok);
			decode_stream = encode_stream;
			decode_stream.Seek(0,SprotoStream.SEEK_BEGIN);
			Console.WriteLine("decode_stream.Position:{0}",decode_stream.Position);
			//SprotoHelper.PrintBytes(decode_stream.Buffer,0,length);
			decode_obj = sproto.Decode("Data",decode_stream);
			SprotoHelper.Assert(decode_stream.Position == length);
			Int64 decode_number = decode_obj["number"];
			Int64 decode_bignumber = decode_obj["bignumber"];
			SprotoHelper.Assert(decode_number == obj["number"]);
			SprotoHelper.Assert(decode_bignumber == obj["bignumber"]);

			Console.WriteLine("TestSprotoCodec.Run ok");
		}
	}
}

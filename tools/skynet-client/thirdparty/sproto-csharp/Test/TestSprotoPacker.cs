using System;
using System.Collections.Generic;
using Sproto;

namespace TestSproto {
	public static class TestSprotoPacker {
		public static void Run () {
			Console.WriteLine("TestSprotoPacker.Run ...");
			SprotoPacker packer = new SprotoPacker();
			Console.WriteLine("=====example 1=====");
			byte[] input = {
				0x08,0x00,0x00,0x00,0x03,0x00,0x02,0x00,
				0x19,0x00,0x00,0x00,0xaa,0x01,0x00,0x00,
			};

			byte[] expect = {
				0x51,0x08,0x03,0x02,
				0x31,0x19,0xaa,0x01,
			};

			int pack_size = 0;
			byte[] pack_output = packer.Pack(input,0,input.Length,out pack_size);
			SprotoHelper.PrintBytes(pack_output,0,pack_size);
			SprotoHelper.Assert(pack_size == expect.Length);
			bool ok = true;
			for (int i = 0; i < pack_size; i++) {
				if (pack_output[i] != expect[i]) {
					ok = false;
					break;
				}
			}
			SprotoHelper.Assert(ok);
			int unpack_size = 0;
			byte[] unpack_output = packer.Unpack(pack_output,0,pack_size,out unpack_size);
			SprotoHelper.Assert(unpack_size == input.Length);
			ok = true;
			for (int i = 0; i < input.Length; i++) {
				if (input[i] != unpack_output[i]) {
					ok = false;
					break;
				}
			}
			SprotoHelper.Assert(ok);

			Console.WriteLine("=====example 2=====");
			input = new byte[30];
			for (int i = 0; i < input.Length; i++) {
				input[i] = 0x8a;
			}

			expect = new byte[2+32];
			expect[0] = 0xff;
			expect[1] = 0x03;
			for (int i = 0; i < input.Length; i++) {
				expect[2+i] = 0x8a;
			}
			expect[input.Length+2] = 0x00;
			expect[input.Length+3] = 0x00;

			pack_size = 0;
			pack_output = packer.Pack(input,0,input.Length,out pack_size);
			SprotoHelper.PrintBytes(pack_output,0,pack_size);
			SprotoHelper.Assert(pack_size == expect.Length);
			ok = true;
			for (int i = 0; i < pack_size; i++) {
				if (pack_output[i] != expect[i]) {
					ok = false;
					break;
				}
			}
			SprotoHelper.Assert(ok);
			unpack_size = 0;
			unpack_output = packer.Unpack(pack_output,0,pack_size,out unpack_size);
			//SprotoHelper.PrintBytes(unpack_output,0,unpack_size);
			// 30 byte expand to 32 byte
			SprotoHelper.Assert(unpack_size == input.Length+2);
			ok = true;
			for (int i = 0; i < input.Length; i++) {
				if (input[i] != unpack_output[i]) {
					ok = false;
					break;
				}
			}
			for (int i = input.Length; i < unpack_size; i++) {
				if (unpack_output[i] != 0) {
					ok = false;
					break;
				}
			}
			SprotoHelper.Assert(ok);

			// best case
			Console.WriteLine("=====example 3=====");
			int length = 2048;
			input = new byte[length];
			for (int i = 0; i < input.Length; i++) {
				input[i] = 0x00;
			}

			expect = new byte[length/8];
			for (int i = 0; i < expect.Length; i++) {
				expect[i] = 0x00;
			}

			pack_size = 0;
			pack_output = packer.Pack(input,0,input.Length,out pack_size);
			SprotoHelper.PrintBytes(pack_output,0,pack_size);
			SprotoHelper.Assert(pack_size == expect.Length);
			ok = true;
			for (int i = 0; i < pack_size; i++) {
				if (pack_output[i] != expect[i]) {
					ok = false;
					break;
				}
			}
			SprotoHelper.Assert(ok);
			unpack_size = 0;
			unpack_output = packer.Unpack(pack_output,0,pack_size,out unpack_size);
			SprotoHelper.Assert(unpack_size == input.Length);
			ok = true;
			for (int i = 0; i < unpack_size; i++) {
				if (input[i] != unpack_output[i]) {
					ok = false;
					break;
				}
			}
			SprotoHelper.Assert(ok);


			// worst case
			Console.WriteLine("=====example 4=====");
			length = 2048;
			input = new byte[length];
			for (int i = 0; i < input.Length; i++) {
				input[i] = 0x11;
			}

			expect = new byte[length+2];
			expect[0] = 0xff;
			expect[1] = (byte)(length/8-1);
			for (int i = 0; i < input.Length; i++) {
				expect[2+i] = 0x11;
			}

			pack_size = 0;
			pack_output = packer.Pack(input,0,input.Length,out pack_size);
			SprotoHelper.PrintBytes(pack_output,0,pack_size);
			SprotoHelper.Assert(pack_size == expect.Length);
			ok = true;
			for (int i = 0; i < pack_size; i++) {
				if (pack_output[i] != expect[i]) {
					ok = false;
					break;
				}
			}
			SprotoHelper.Assert(ok);
			unpack_size = 0;
			unpack_output = packer.Unpack(pack_output,0,pack_size,out unpack_size);
			SprotoHelper.Assert(unpack_size == input.Length);
			ok = true;
			for (int i = 0; i < unpack_size; i++) {
				if (input[i] != unpack_output[i]) {
					ok = false;
					break;
				}
			}
			SprotoHelper.Assert(ok);

			// part worst case
			Console.WriteLine("=====example 5=====");
			length = 2048+2;
			input = new byte[length];
			for (int i = 0; i < length-2; i++) {
				input[i] = 0x11;
			}
			input[length-2] = 0x00;
			input[length-1] = 0x01;

			expect = new byte[2048+4];
			expect[0] = 0xff;
			expect[1] = (byte)((length-2)/8-1);
			for (int i = 0; i < length-2; i++) {
				expect[2+i] = 0x11;
			}
			expect[length+0] = 0x02;
			expect[length+1] = 0x01;

			pack_size = 0;
			pack_output = packer.Pack(input,0,input.Length,out pack_size);
			SprotoHelper.PrintBytes(pack_output,0,pack_size);
			SprotoHelper.Assert(pack_size == expect.Length);
			int need_length = SprotoPacker.NeedBufferSize("pack",length);
			SprotoHelper.Assert(need_length >= expect.Length);
			ok = true;
			for (int i = 0; i < pack_size; i++) {
				if (pack_output[i] != expect[i]) {
					ok = false;
					break;
				}
			}
			SprotoHelper.Assert(ok);
			unpack_size = 0;
			unpack_output = packer.Unpack(pack_output,0,pack_size,out unpack_size);
			// 2048+2 byte expand to 2048+8 byte
			SprotoHelper.Assert(unpack_size == input.Length+6);
			ok = true;
			for (int i = 0; i < input.Length; i++) {
				if (input[i] != unpack_output[i]) {
					ok = false;
					break;
				}
			}
			for (int i = input.Length; i < unpack_size; i++) {
				if (unpack_output[i] != 0) {
					ok = false;
					break;
				}
			}
			SprotoHelper.Assert(ok);

			Console.WriteLine("TestSprotoPacker.Run ok");
		}
	}
}

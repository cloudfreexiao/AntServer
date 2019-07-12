using System;

namespace Sproto {
	public class SprotoStream {
		public const int SEEK_BEGIN = 0;
		public const int SEEK_CUR = 1;
		public const int SEEK_END = 2;
		public const int MAX_SIZE = 0x1000000;

		private byte[] buffer;
		private int pos;

		public SprotoStream () {
			this.buffer = new byte[256];
			this.pos = 0;
		}
		
		public byte[] Buffer {
			get {return this.buffer;}
			set {this.buffer = value;}
		}
		public int Position {
			get {return this.pos;}
		}
		public int Capcity {
			get {return this.buffer.Length;}
		}

		public void Expand (int size) {
			if (this.Capcity - this.pos < size) {
				int old_capcity = this.Capcity;
				int capcity = this.Capcity;
				while (capcity - this.pos < size) {
					capcity = capcity * 2;
				}
				if (capcity >= SprotoStream.MAX_SIZE) {
					SprotoHelper.Error("object is too large(>{0})",SprotoStream.MAX_SIZE);
				}
				byte [] new_buffer = new byte[capcity];
				for (int i = 0; i < old_capcity; i++) {
					new_buffer[i] = this.buffer[i];
				}
				this.buffer = new_buffer;
			}
			
		}

		private void _WriteByte (byte b) {
			this.buffer[this.pos++] = b;
		}

		public void WriteByte (byte b) {
			this.Expand(sizeof(byte));
			this._WriteByte(b);
		}

		public void Write (byte[] data,int offset,int length) {
			this.Expand(length);
			for (int i = 0; i < length; i++) {
				byte b = data[offset + i];
				this._WriteByte(b);
			}
		}

		public void Write(byte[] data,int offset,UInt32 length) {
			this.Write(data,offset,(int)length);
		}

		public int Seek (int offset,int whence) {
			switch (whence) {
				case SprotoStream.SEEK_BEGIN:
					this.pos = 0 + offset;
					break;
				case SprotoStream.SEEK_CUR:
					this.pos = this.pos + offset;
					break;
				case SprotoStream.SEEK_END:
					this.pos = this.Capcity + offset;
					break;
				default:
					SprotoHelper.Error("[Sproto.Stream.Seek] invalid whence:{0}",whence);
					break;
			}
			this.Expand(0);
			return this.pos;
		}

		public int Seek (UInt32 offset,int whence) {
			return this.Seek((int)offset,whence);
		}

		public byte ReadByte () {
			return this.buffer[this.pos++];
		}

		public int Read (byte[] bytes,int offset,int length) {
			for (int i = 0; i < length; i++) {
				if (this.pos >= this.Capcity) {
					return i;
				}
				bytes[offset + i] = this.ReadByte();
			}
			return length;
		}

		public int Read (byte[] bytes,int offset,UInt32 length) {
			return this.Read(bytes,offset,(int)length);
		}
	}
}

using System;

namespace Sproto {
	public class SprotoPacker {
		public static int NeedBufferSize(string type,int length) {
			if (type == "pack") {
				// the worst-case space overhead of packing is 2 bytes per 2KiB of input (256 words = 2KiB).
				length = (length+7)&(~7);
				int need_length = (length + 2047) / 2048 * 2 + length + 2;
				return need_length;
			} else {
				return length * 8;
			}
		}

		public byte[] Pack (byte[] src,int start,int length,out int size,byte[] dest=null) {
			if (null == dest) {
				int dest_length = SprotoPacker.NeedBufferSize("pack",length);
				dest = new byte[dest_length];
			}
			int ff_n = 0;
			int ff_srcpos = 0;
			int ff_destpos = 0;
			int srcpos = start;
			int destpos = 0;
			for (int i = 0; i < length; i+=8) {
				int n;
				int padding = i + 8 - length;
				if (padding > 0) {
					byte[] tmp = new byte[8];
					//this.memcpy(tmp,0,src,srcpos,8-padding);
					for (int j = 0; j < 8-padding; j++) {
						tmp[j] = src[srcpos+j];
					}
					for (int j = 0; j < padding; j++) {
						tmp[7-j] = 0;
					}
					n = this.pack_seg(dest,destpos,tmp,0,ff_n);
				} else {
					n = this.pack_seg(dest,destpos,src,srcpos,ff_n);
				}
				if (10 == n) {
					ff_srcpos = srcpos;
					ff_destpos = destpos;
					ff_n = 1;
				} else if (8 == n && ff_n > 0) {
					ff_n++;
					if (ff_n == 256) {
						this.write_ff(dest,ff_destpos,src,ff_srcpos,ff_n*8);
						ff_n = 0;
					}
				} else {
					if (ff_n > 0) {
						this.write_ff(dest,ff_destpos,src,ff_srcpos,ff_n*8);
						ff_n = 0;
					}
				}
				srcpos += 8;
				destpos += n;
			}
			if (ff_n == 1)
				this.write_ff(dest,ff_destpos,src,ff_srcpos,8);
			else if (ff_n > 1)
				this.write_ff(dest,ff_destpos,src,ff_srcpos,length-(ff_srcpos-start));
			size = destpos;
			return dest;
		}

		public byte[] Unpack (byte[] src,int start,int length,out int size,byte[] dest=null) {
			if (null == dest) {
				int dest_length = SprotoPacker.NeedBufferSize("unpack",length);
				dest = new byte[dest_length];
			}
			int srcpos = start;
			int destpos = 0;
			while (srcpos < start+length) {
				int n;
				byte header = src[srcpos++];
				if (0xff == header) {
					n = src[srcpos++];
					n = (n+1)*8;
					this.memcpy(dest,destpos,src,srcpos,n);
					srcpos += n;
					destpos += n;
				} else {
					for (int i = 0; i < 8; i++) {
						bool notzero = ((header >> i) & 1) == 1 ? true : false;
						if (notzero) {
							byte b = src[srcpos++];
							dest[destpos++] = b;
						} else {
							dest[destpos++] = 0;
						}
					}
				}
			}
			if (srcpos != start+length) {
				SprotoHelper.Error("[SprotoPacker.UnPack] fail");
			}
			size = destpos;
			return dest;
		}

		private void write_ff(byte[] dest,int destpos,byte[] src,int srcpos,int n) {
			int align8_n = (n+7)&(~7);
			dest[destpos+0] = (byte)0xff;
			dest[destpos+1] = (byte)(align8_n/8-1);
			destpos += 2;
			this.memcpy(dest,destpos,src,srcpos,n);
			for (int i = 0; i < align8_n - n; i++) {
				dest[destpos+n+i] = (byte)0x00;
			}
		}

		private void memcpy (byte[] dest,int destpos,byte[] src,int srcpos,int length) {
			for (int i = 0; i < length; i++) {
				dest[destpos+i] = src[srcpos+i];
			}
		}

		private int pack_seg (byte[] dest,int destpos,byte[] src,int srcpos,int ff_n) {
			byte header = 0;
			int notzero = 0;
			int header_pos = destpos;
			destpos++;
			for (int i = 0; i < 8; i++) {
				if (src[srcpos] != 0) {
					notzero++;
					header |= (byte)(1 << i);
					dest[destpos] = src[srcpos];
					destpos++;
				}
				srcpos++;
			}
			if ((notzero == 7 || notzero == 6) && ff_n > 0) {
				notzero = 8;
			}
			if (notzero == 8) {
				if (ff_n > 0)
					return 8;
				else
					return 10;
			}
			dest[header_pos] = header;
			return notzero + 1;
		}
	}
}

using System.Collections;
using System.IO;
using System;

/*
0 压缩
这样打包出来的数据的长度必定 4 的倍数，里面会有大量的 0 。我们可以借鉴 Cap'n proto 的压缩方案 ：
首先，如果数据长度不是 8 的倍数，就补 4 个 0 。
按 8 个字节一组做压缩，用一个字节 (8bit) 表示各个字节是否为 0 ，然后把非 0 的字节紧凑排列，例如：
unpacked (hex):  08 00 00 00 03 00 02 00   19 00 00 00 aa 01 00 00
packed (hex):  51 08 03 02   31 19 aa 01
当 8 个字节全不为 0 时，这个标识字节为 FF ，这时后面跟一个字节表示有几组 (1~256) 连续非 0 组。 
所以，在最坏情况下，如果有 2K 的全不为 0 的数据块，需要增加两个字节 FF FF 的数据头（表示后续有 256 组 8 字节的非 0 块）。
*/

public class SpPacker
{
    private static int PackSeg(byte[] src, int src_offset, SpStream output, int n)
    {
        byte header = 0;
        int notzero = 0;

        int dest_begin = output.Position;
        output.Position++;

        for (int i = 0; i < 8; i++)
        {
            if (src[src_offset + i] != 0)
            {
                notzero++;
                header |= (byte)(1 << i);

                output.Write(src[src_offset + i]);
            }
        }

        if ((notzero == 7 || notzero == 6) && n > 0)
            notzero = 8;

        if (notzero == 8)
        {
            if (n > 0)
                return 8;
            else
                return 10;
        }

        int dest_end = output.Position;
        output.Position = dest_begin;
        output.Write(header);
        output.Position = dest_end;

        return notzero + 1;
    }

    public static void WriteFF(byte[] src, int src_offset, SpStream output, int n, int correctPos)
    {
        int align8_n = (n + 7) & (~7);
        output.Write((byte)0xff);
        output.Write((byte)(align8_n / 8 - 1));
        output.Write(src, src_offset, n);
        for (int i = 0; i < align8_n - n; i++)
            output.Write((byte)0);
        output.CorrectLength(correctPos);
    }

    public static SpStream Pack(SpStream input)
    {
        SpStream stream = new SpStream();

        int pos = input.Position;
        if (Pack(input, stream) == false)
        {
            int size = stream.Position;
            size = ((size + 7) / 8) * 8;
            stream = new SpStream(size);

            input.Position = pos;
            // do we need this check? it's not possible it will return false this time
            if (Pack(input, stream) == false)
                return null;
        }

        return stream;
    }

    public static bool Pack(SpStream input, SpStream output)
    {
        int src_size = input.Length;
        if (src_size % 8 != 0)
        {
            int new_size = ((src_size + 7) / 8) * 8;
            if (input.Capacity < new_size)
            {
                SpStream new_input = new SpStream(new_size);
                Array.Copy(input.Buffer, input.Offset, new_input.Buffer, new_input.Offset, input.Length);
                new_input.Position = new_input.Offset;
                input = new_input;
                src_size = new_size;
            }
            else
            {
                int pos = input.Position;
                input.Position = input.Tail;
                for (int i = src_size; i < new_size; i++)
                {
                    input.Write((byte)0);
                }
                input.Position = pos;
            }
        }

        int src_start = input.Offset;
        int src_offset = input.Offset;
        byte[] src = input.Buffer;

        int ff_n = 0;
        int ff_src_start = 0;
        int ff_dest_start = 0;

        for (; src_offset < src_size; src_offset += 8)
        {
            int pos = output.Position;
            int n = PackSeg(src, src_offset, output, ff_n);

            if (n == 10)
            {
                ff_src_start = src_offset;
                ff_dest_start = pos;
                ff_n = 1;
            }
            else if (n == 8 && ff_n > 0)
            {
                ff_n++;
                if (ff_n == 256)
                {
                    output.Position = ff_dest_start;
                    WriteFF(src, ff_src_start, output, 256 * 8, n);
                    ff_n = 0;
                }
            }
            else
            {
                if (ff_n > 0)
                {
                    output.Position = ff_dest_start;
                    WriteFF(src, ff_src_start, output, ff_n * 8, n);
                    ff_n = 0;
                }
            }

            output.Position = pos + n;
        }

        if (ff_n == 1)
        {
            output.Position = ff_dest_start;
            WriteFF(src, ff_src_start, output, 8, 0);
        }
        else if (ff_n > 1)
        {
            output.Position = ff_dest_start;
            WriteFF(src, ff_src_start, output, src_size - (ff_src_start - src_start), 0);
        }

        return (output.IsOverflow() == false);
    }

    public static SpStream Unpack(SpStream input)
    {
        SpStream stream = new SpStream();

        int pos = input.Position;
        if (Unpack(input, stream) == false)
        {
            stream = new SpStream(stream.Position);

            input.Position = pos;
            if (Unpack(input, stream) == false)
                return null;
        }

        return stream;
    }

    public static bool Unpack(SpStream input, SpStream output)
    {
        int src_size = input.Tail;
        int src_offset = input.Offset;
        byte[] src = input.Buffer;

        while (src_offset < src_size)
        {
            byte header = src[src_offset];
            src_offset++;

            if (header == 0xff)
            {
                if (src_offset > src_size)
                    return false;

                int n = (src[src_offset] + 1) * 8;
                if (src_size - src_offset < n + 1)
                    return false;

                src_offset++;
                output.Write(src, src_offset, n);
                src_offset += n;
            }
            else
            {
                for (int i = 0; i < 8; i++)
                {
                    int nz = (header >> i) & 1;
                    if (nz != 0)
                    {
                        if (src_offset > src_size)
                            return false;

                        output.Write(src[src_offset]);
                        src_offset++;
                    }
                    else
                    {
                        output.Write((byte)0);
                    }
                }
            }
        }

        return (output.IsOverflow() == false);
    }
}

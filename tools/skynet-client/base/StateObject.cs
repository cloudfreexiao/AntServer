namespace Skynet.DotNetClient
{
    internal class StateObject
    {
        private const int BufferSize = 1024;
        public readonly byte[] buffer = new byte[BufferSize];
        public int offset = 0;
        
        public void WriteBytes(byte[] bytes, int start, int length)
        {
            for (var i = 0; i < length; i++)
            {
                buffer[offset] = bytes[start + i];
                offset++;
            }
        }

        public int CheckLineFeed(char lineFeed)
        {
            for (var i = 0; i < offset; i++)
            {
                var c = (char)buffer[i];
                if(c.Equals(lineFeed))
                {
                    return i;
                }
            }
            return -1;
        }

    }
}
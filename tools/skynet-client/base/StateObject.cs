namespace Skynet.DotNetClient
{
    class StateObject
    {
        public const int BufferSize = 1024;
        public byte[] buffer = new byte[BufferSize];
        public int offset = 0;
        
        public void writeBytes(byte[] bytes, int start, int length)
        {
            for (int i = 0; i < length; i++)
            {
                buffer[offset] = bytes[start + i];
                offset++;
            }
        }

        public int checkLineFeed(char lineFeed)
        {
            for (int i = 0; i < offset; i++)
            {
                char c = (char)buffer[i];
                if(c.Equals(lineFeed))
                {
                    return i;
                }
            }
            return -1;
        }

    }
}
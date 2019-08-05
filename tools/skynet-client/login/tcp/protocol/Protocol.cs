namespace Skynet.DotNetClient.Login.TCP
{
    using System;
    using System.Net.Sockets;

    public class Protocol
    {
        private readonly LoginClient _client;
        private readonly Transporter _transporter;

        public Protocol(LoginClient sc, Socket socket)
        {
            _client = sc;
            _transporter = new Transporter(socket, this) {onDisconnect = Disconnect};
            _transporter.Start();
        }
        
        public void Send(object packet)
        {
            var data = packet as byte[];
            if (data == null || data.Length <= 0)
            {
                return;
            }
//            var msg = Merge(data, _transporter.GetLineFeed());
//            if(msg == null)
//            {
//                return;
//            }

            _transporter.Send(data);
        }
        
        private  byte[] Merge(byte[] source, byte append)
        {
            var len = source.Length + 1;
            var merge = new byte[len];
            Array.Copy(source, 0, merge, 0, source.Length);
            merge[source.Length] = append;
            return merge;
        }

        internal void ProcessMessage(byte[] bytes)
        {
            _client.ProcessMessage(bytes);
        }

        private void Disconnect()
        {
            _client.Disconnect();
        }

        internal void Close()
        {
            _transporter.Close();
        }
    }
}
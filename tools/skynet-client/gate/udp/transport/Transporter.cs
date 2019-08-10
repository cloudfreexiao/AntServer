using System;
using System.Net;
using System.Net.Sockets;
using Skynet.DotNetClient.Utils.Logger;

namespace Skynet.DotNetClient.Gate.UDP
{
    internal class Transporter
    {
        private readonly UdpClient _udpClient;
        
        private readonly IGateClient _client;

        private  IPEndPoint _endPoint;
        
        public Transporter(IGateClient client)
        {
            _client = client;
            _udpClient = new UdpClient();
        }
        
        public void Connect(string host, int port)
        {
            _client.NetWorkChanged(NetWorkState.Connecting);
            IPAddress ipAddress = null;

            try
            {
                var addresses = Dns.GetHostEntry(host).AddressList;
                foreach (var item in addresses)
                {
                    if (item.AddressFamily != AddressFamily.InterNetwork) continue;
                    ipAddress = item;
                    break;
                }
            }
            catch (Exception)
            {
                _client.NetWorkChanged(NetWorkState.Error);
                return;
            }

            if (ipAddress == null)
            {
                throw new Exception("can not parse host : " + host);
            }

            try
            {
                _endPoint = new IPEndPoint(ipAddress, port);
                _udpClient.Connect(host, port);
                
                Receive();
                _client.NetWorkChanged(NetWorkState.Connected);
            }
            catch (SocketException)
            {
                _client.NetWorkChanged(NetWorkState.Error);
            }
        }

        public void Close()
        {
            _udpClient.Close();
        }

        public void RawSend(byte[] data, int length)
        {
            if (length >= 512)
            {
                SkynetLogger.Error(Channel.Udp, "Send Data overload 1 MTU");
            }
            _udpClient.SendAsync(data, length);
        }
        
//        public async Task Update()
//        {
//            var result = await _udpClient.ReceiveAsync();
//            var len = result.Buffer.Length;
//            if (len > 0)
//            {
//                var resp = Protocol.Parse(result.Buffer, result.Buffer.Length);
//                _client.ProcessMessage(resp);
//            }
//            else if (len < 0)
//            {
//                _client.NetWorkChanged(NetWorkState.Closed);
//            }
//        }

        private void Receive()
        {
            _udpClient.BeginReceive(EndReceive, null);
        }

        private  void EndReceive(IAsyncResult asr)
        {
            try
            {
                var buffer = _udpClient.EndReceive(asr, ref _endPoint);
                if (buffer.Length > 0)
                {
                    var resp = Protocol.Parse(buffer, buffer.Length);
                    _client.ProcessMessage(resp);
                }
                else
                {
                    _client.NetWorkChanged(NetWorkState.Closed);
                }
            }
            catch (SocketException)
            {
                _client.NetWorkChanged(NetWorkState.Error);
            }
        }
        
    }
}

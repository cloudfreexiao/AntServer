using System.Net.Sockets;
using System.Threading.Tasks;
using Skynet.DotNetClient.Utils.Logger;

namespace Skynet.DotNetClient.Gate.UDP
{
    internal class Transporter
    {
        private readonly UdpClient _udpClient;
        
        private readonly IGateClient _client;

        public Transporter(IGateClient client)
        {
            _client = client;
            _udpClient = new UdpClient();
        }
        
        public void Connect(string host, int port)
        {
            _udpClient.Connect(host, port);
            _client.NetWorkChanged(NetWorkState.Connected);
        }

        public void Close()
        {
            _udpClient.Close();
        }

        public void RawSend(byte[] data, int length)
        {
            _udpClient.Send(data, length);
        }

        public async Task Update()
        {
            var result = await _udpClient.ReceiveAsync();
            var len = result.Buffer.Length;
            if (len > 0)
            {
                var resp = Protocol.Parse(result.Buffer, result.Buffer.Length);
                _client.ProcessMessage(resp);
            }
            else if (len < 0)
            {
                _client.NetWorkChanged(NetWorkState.Closed);
            }
        }
        
    }
}

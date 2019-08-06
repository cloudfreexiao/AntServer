namespace Skynet.DotNetClient.Gate.WS
{
    using System.Text;
    using Sproto;
    using Utils.Logger;

    public class Protocol
    {
        private readonly SpStream _stream = new SpStream (1024);
        private readonly SpRpc _rpc;

        private readonly IGateClient _client;

        public Protocol(IGateClient sc)
        {
            _client = sc;

            var loader = new ProtocolLoader();
            _rpc = loader.CreateRpcProto();
        }
        
        public SpStream Pack (string proto, int session, SpObject args)
        {
            _stream.Reset ();

            if (proto != "heartbeat")
            {
                SkynetLogger.Info(Channel.NetDevice,"Send Request : " + proto + ", session : " + session);;
            }

            _rpc.Request (proto, args, session, _stream);
            return _stream;
        }

        public void ProcessMessage(string data)
        {
            var bytes = Encoding.UTF8.GetBytes(data);
            ProcessMessage(bytes);
        }
        
        public void ProcessMessage(byte[] bytes)
        {
            var stream = new SpStream (bytes, 0, bytes.Length, bytes.Length);
            var result = _rpc.Dispatch (stream);
            _client.ProcessMessage (result);
        }
        
    }
}
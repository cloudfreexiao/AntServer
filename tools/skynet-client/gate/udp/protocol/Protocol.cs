namespace Skynet.DotNetClient.Gate.UDP
{
    using System.Text;
    using Sproto;
    using Utils.Logger;
    
    public class Protocol
    {
        private readonly SpStream _stream = new SpStream (1024);
        private readonly SpRpc _rpc;

        private readonly IGateClient _client;

        private readonly int _session;
        private readonly byte[] _secret = new byte[8];
        
        public Protocol(IGateClient sc, int session, byte[] secret)
        {
            _client = sc;
            _session = session;
            _secret = secret;
            
            var loader = new ProtocolLoader();
            _rpc = loader.CreateBattleProto();
        }
    
        public SpStream Pack (string proto, int session, SpObject args)
        {
            _stream.Reset ();

            if (proto != "heartbeat")
            {
                SkynetLogger.Info(Channel.NetDevice,"Send Request : " + proto + ", session : " + session);
            }

            _stream.Write ((int)_session);
//            _stream.Buffer[0] = (byte)((_session >> 24) & 0xff);
//            _stream.Buffer[1] = (byte)((_session >> 16) & 0xff);
//            _stream.Buffer[2] = (byte)((_session >> 8) & 0xff);
//            _stream.Buffer[3] = (byte)(_session  & 0xff);
            _stream.Write(_secret);

            _rpc.Request (proto, args, session, _stream);
            return _stream;
        }
        
        

        public void ProcessMessage(string data)
        {
            var bytes = Encoding.UTF8.GetBytes(data);
            ProcessMessage(bytes);
        }

        private void ProcessMessage(byte[] bytes)
        {
            var stream = new SpStream (bytes, 0, bytes.Length, bytes.Length);
            var result = _rpc.Dispatch (stream);
            _client.ProcessMessage (result);
        }
    
    }
    
}
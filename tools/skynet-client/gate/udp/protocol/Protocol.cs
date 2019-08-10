using Skynet.DotNetClient.Utils.Logger;

namespace Skynet.DotNetClient.Gate.UDP
{
    using System.Text;
    using Sproto;
    
    internal static class Protocol
    {
        private static readonly SpStream _stream = new SpStream (1024);
        private static SpRpc _rpc;
        
        private static int _session;
        private static byte[] _secret;
        
        public static void Init( int session, string secret)
        {
            _session = session;
            _secret = Encoding.UTF8.GetBytes(secret);
            
            var loader = new ProtocolLoader();
            _rpc = loader.CreateBattleProto();
        }
        
        public static SpStream Pack(string proto, int session, SpObject args)
        {
            _stream.Reset ();
            
            SkynetLogger.Info(Channel.Udp,"Send Request : " + proto + ", session : " + session);

            _stream.Write(_session);
            _stream.Write(_secret);
            
            _rpc.Request (proto, args, session, _stream);

            return _stream;
        }
        
        public static SpRpcResult Parse(byte[] bytes, int dataLength)
        {
            var stream = new SpStream (bytes, 0, dataLength, dataLength);
            return _rpc.Dispatch (stream);
        }
        

    }
}
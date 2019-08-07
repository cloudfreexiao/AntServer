using Skynet.DotNetClient;
using Skynet.DotNetClient.Utils.Logger;

namespace MiniUDP
{
    using System;
    using System.Text;
    using Sproto;
    
    internal static class SprotoEncoding
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
        
        public static SpStream PackPayload(string proto, int session, SpObject args)
        {
            _stream.Reset ();
            
            if (proto != "heartbeat")
            {
                SkynetLogger.Info(Channel.NetDevice,"Send Request : " + proto + ", session : " + session);
            }

            _stream.Write(_session);

            _stream.Write(_secret);
            _rpc.Request (proto, args, session, _stream);

            return _stream;
        }
        
        public static SpRpcResult ParseSproto(byte[] bytes, int dataLength)
        {
            var stream = new SpStream (bytes, 0, dataLength, dataLength);
            return _rpc.Dispatch (stream);
        }
        
        internal static bool ReadPayload(
            Func<NetEventType, NetPeer, NetEvent> eventFactory,
            NetPeer peer,
            byte[] buffer,
            int length,
            out ushort sequence,
            out NetEvent et)
        {
            et = null;
            //TODO: 待优化 加个 包头可以 避免 两次 解析 sproto 数据 或者 event 里包含 sproto 数据 暂时 现在这么处理
            var rpcResult = ParseSproto(buffer, length);
            sequence = (ushort)rpcResult.Session;
            
            et = eventFactory.Invoke(NetEventType.Payload, peer);
            return et.ReadData(buffer, 0, (ushort)length);
        }
        
    }
}
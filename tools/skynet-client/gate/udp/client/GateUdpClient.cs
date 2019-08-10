namespace Skynet.DotNetClient.Gate.UDP
{
    using System;
    using Sproto;
    using Utils.Logger;
    
    public sealed class GateUdpClient : IGateClient, IDisposable
    {
        public event Action<NetWorkState> OnNetworkStateCallBack;
        private bool _disposed;

        private Transporter _connector;
        private int _session = 1;
        
        public GateUdpClient(Action<NetWorkState> networkCallBack)
        {
            OnNetworkStateCallBack = networkCallBack;
            _disposed = false;
        }

        public void Connect(BattleSession battleSession)
        {
            Protocol.Init(battleSession.session, battleSession.secret);

            _connector = new Transporter(this);
            
            var endpoint = battleSession.host + ":" + battleSession.port;
            SkynetLogger.Info(Channel.Udp,"Udp Client URL " + endpoint);
            _connector.Connect(battleSession.host, battleSession.port);
        }

        public void NetWorkChanged(NetWorkState state)
        {
            OnNetworkStateCallBack?.Invoke(state);
        }
        
        public void Request(string proto, Action<SpObject> action)
        {
            Request(proto, null, action);
        }

        public void Request(string proto, SpObject msg, Action<SpObject> action)
        {
            var spRes = Protocol.Pack(proto, _session, msg);
            _connector.RawSend(spRes.Buffer, spRes.Length);
            _session++;
        }

        public void ProcessMessage(SpRpcResult msg)
        {
            if (msg.ud != 0)
            {
                SkynetLogger.Error(Channel.Udp,"udp client resp error code is: " + msg.ud);
                return;
            }
			
            switch (msg.Op) 
            {
                case SpRpcOp.Request:
                    SkynetLogger.Info(Channel.Udp, "udp client recv Request : " + msg.Protocol.Name + ", session : " + msg.Session);
                    Utils.Util.DumpObject (msg.Data);
                    break;
                case SpRpcOp.Response:
                    if (msg.Protocol.Name != "heartbeat")
                    {
                        SkynetLogger.Info(Channel.Udp,"udp client recv Response : " + msg.Protocol.Name + ", session : " + msg.Session);
                        Utils.Util.DumpObject (msg.Data);
                    }
                    break;
                case SpRpcOp.Unknown:
                    break;
                default:
                    throw new ArgumentOutOfRangeException();
            }
        }
        
        public void Disconnect()
        {
            Dispose();
        }

        public void Dispose() {
            Dispose (true);
            GC.SuppressFinalize ((object)this);
        }

        private void Dispose(bool disposing)
        {
            if (_disposed)
                return;

            if (!disposing) return;
            try
            {
                _connector?.Close();
            }
            catch (Exception)
            {
                //todo : 有待确定这里是否会出现异常，这里是参考之前官方github上pull request。emptyMsg
            }

            _disposed = true;
        }
    }
}
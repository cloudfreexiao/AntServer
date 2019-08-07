namespace Skynet.DotNetClient.Gate.UDP
{
    using System;
    using Sproto;
    using Utils.Logger;
    using MiniUDP;
    
    public sealed class GateUdpClient : IGateClient, IDisposable
    {
        public event Action<NetWorkState> OnNetworkStateCallBack;
        private bool _disposed;

        private UdpConnector _connector;
        
        public GateUdpClient(Action<NetWorkState> networkCallBack)
        {
            OnNetworkStateCallBack = networkCallBack;
            _disposed = false;
        }

        public void Connect(UdpSession udpSession)
        {
            SprotoEncoding.Init(udpSession.session, udpSession.secret);

            _connector = new UdpConnector( this,"UdpClient", false);
            
            var endpoint = udpSession.host + ":" + udpSession.port;
            SkynetLogger.Info(Channel.NetDevice,"Udp Client URL " + endpoint);
            _connector.Connect(endpoint);
        }

        public void Update()
        {
            _connector?.Update();
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
            _connector.SendPayload(proto, msg);
        }

        public void ProcessMessage(SpRpcResult msg)
        {
            if (msg.ud != 0)
            {
                SkynetLogger.Error(Channel.NetDevice,"udp client resp error code is: " + msg.ud);
                return;
            }
			
            switch (msg.Op) 
            {
                case SpRpcOp.Request:
                    SkynetLogger.Info(Channel.NetDevice, "udp client recv Request : " + msg.Protocol.Name + ", session : " + msg.Session);
                    Utils.Util.DumpObject (msg.Data);
                    break;
                case SpRpcOp.Response:
                    if (msg.Protocol.Name != "heartbeat")
                    {
                        SkynetLogger.Info(Channel.NetDevice,"udp client recv Response : " + msg.Protocol.Name + ", session : " + msg.Session);
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
                _connector.Stop();
            }
            catch (Exception)
            {
                //todo : 有待确定这里是否会出现异常，这里是参考之前官方github上pull request。emptyMsg
            }

            _disposed = true;
        }
    }
}
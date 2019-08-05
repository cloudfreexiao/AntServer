namespace Skynet.DotNetClient.Gate.UDP
{
    using System;
    using System.Text;
    using MiniUDP;
    
    
    public class GateUdpClient : IDisposable
    {
        private bool _disposed;
        private int _session;

        private UdpSession _udpSession;
        
        private NetPeer _peer;
        private UdpConnector _connector;
//        private readonly UDPClock _fastClock;
        
        private bool _loop;
        
        public GateUdpClient(UdpSession udpSession)
        {
//            _fastClock = new UDPClock(0.01f);
//            _fastClock.OnFixedUpdate += SendPayload;

            _udpSession = udpSession;
            
            _loop = true;
            
            _session = 1;
            _disposed = false;
        }

        public void Connect()
        {
            _connector = new UdpConnector("UDPClient", false);

            var endpoint = _udpSession.host + ":" + _udpSession.port.ToString();
            _peer = _connector.Connect(endpoint);
        }

//        public void Start()
//        {
//            while (_loop)
//            {
//                _fastClock.Tick();
//                _connector.Update();
//            }
//        }
//        
        private void SendPayload()
        {
            byte[] data = Encoding.UTF8.GetBytes("Payload " + 1);
            _peer.SendPayload(data, (ushort)data.Length);
        }

        public void Disconnect()
        {
            Dispose();
        }
        
        public void Dispose() {
            Dispose (true);
            GC.SuppressFinalize (this);
        }
        
        protected virtual void Dispose(bool disposing)
        {
            if (_disposed)
                return;

            if (disposing)
            {
                try
                {
                    _loop = false;
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
}
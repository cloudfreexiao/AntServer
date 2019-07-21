namespace Skynet.DotNetClient.Rudp
{
    using System;
    using MiniUDP;
    
    public class RudpClient : IDisposable
    {
        private bool _disposed;
        private int _session;

        private NetPeer _peer;
        private RudpConnector _connector;
        private readonly RudpClock _clock;
        private readonly RudpClock _slowClock;
        
        private bool _loop;
        
        public RudpClient()
        {
            _connector = new RudpConnector("RudpClient", false);
            _clock = new RudpClock(0.01f);
            _clock.OnFixedUpdate += SendPayload;
            
            _slowClock = new RudpClock(1.0f);
            _slowClock.OnFixedUpdate += SendNotification;
            
            _loop = true;
            
            _session = 1;
            _disposed = false;
        }

        public void Connect(string host, int port)
        {
            string endpoint = host + ":" + port.ToString();
            _peer = _connector.Connect(endpoint);
        }


        public void Start()
        {
            while (_loop)
            {
                _clock.Tick();
                _connector.Update();
            }
        }
        
        private void SendPayload()
        {
//            byte[] data = Encoding.UTF8.GetBytes("Payload " + payloadCount);
//            Program.peer.SendPayload(data, (ushort)data.Length);
//            payloadCount++;
        }

        void SendNotification()
        {
//            byte[] data = Encoding.UTF8.GetBytes("Notification " + notificationCount);
//            Program.peer.QueueNotification(data, (ushort)data.Length);
//            notificationCount++;
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
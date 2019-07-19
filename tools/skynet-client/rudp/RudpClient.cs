namespace Skynet.DotNetClient.Rudp
{
    using System;
    using MiniUDP;
    
    public class RudpClient : IDisposable
    {
        private bool _disposed;
        private int _session;

        public RudpClient()
        {
            _session = 1;
            _disposed = false;
        }

        public void Connect(string host, int port)
        {
            
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
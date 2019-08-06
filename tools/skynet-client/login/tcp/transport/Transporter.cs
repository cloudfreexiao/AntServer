namespace Skynet.DotNetClient.Login.TCP
{
    using System;
    using System.Net.Sockets;

    public class Transporter
    {
        private readonly Socket _socket;
        private readonly Protocol _protocol;

        private readonly StateObject _stateObject = new StateObject();
        private TransportState _transportState;

        internal Action onDisconnect = null;

        private readonly StateObject _buffObject = new StateObject();

        /// 协议格式为 数据包+换行符(\n)，即在每个数据包末尾加上一个换行符表示包的结束
        private const char LineFeed = '\n';

        public Transporter(Socket socket, Protocol input)
        {
            _socket = socket;
            _protocol = input;
            
            _transportState = TransportState.ReadBody;
        }

        public byte GetLineFeed()
        {
            return (byte)LineFeed;
        }
        
        internal void Close()
        {
            _transportState = TransportState.Closed;
        }
        
        public void Send(byte[] buffer)
        {
            if (_transportState != TransportState.Closed)
            {
                _socket.BeginSend(buffer, 0, buffer.Length, SocketFlags.None, new AsyncCallback(SendCallback), _socket);
            }
        }
        
        private void SendCallback(IAsyncResult asyncSend)
        {
            if (_transportState == TransportState.Closed) 
                return;
            _socket.EndSend(asyncSend);
        }
        
        public void Start()
        {
            Receive();
        }

        private void Receive()
        {
             _socket.BeginReceive(_stateObject.buffer, 0, 
                _stateObject.buffer.Length, SocketFlags.None, new AsyncCallback(EndReceive), _stateObject);
        }
        
        private void EndReceive(IAsyncResult asyncReceive)
        {
            if (_transportState == TransportState.Closed)
                return;
            
            StateObject state = (StateObject)asyncReceive.AsyncState;
            var socket = _socket;

            try
            {
                var length = socket.EndReceive(asyncReceive);
                if (length > 0)
                {
                    ProcessBytes(state.buffer, 0, length);
                    //Receive next message
                    Receive();
                }
                else
                {
                    onDisconnect?.Invoke();
                }

            }
            catch (SocketException)
            {
                onDisconnect?.Invoke();
            }
        }

        private void ProcessBytes(byte[] bytes, int offset, int limit)
        {
            if (_transportState == TransportState.ReadBody)
            {
                ReadBody(bytes, offset, limit);
            }
        }

        private void ReadBody(byte[] bytes, int start, int length)
        { 
            _buffObject.WriteBytes(bytes, start, length);

            var idx = _buffObject.CheckLineFeed(LineFeed);
            if (idx >= 0)
            {
                var len = idx;
                var requested = new byte[len];
                Array.Copy(_buffObject.buffer, 0, requested, 0, len);
                _protocol.ProcessMessage(requested);

                idx += 1;
                if (idx < _buffObject.offset)
                {
                    //多出来些数据
                    len = _buffObject.offset - idx;
                    var v = new byte[len];
                    Array.Copy(_buffObject.buffer, idx, v, 0, len);
                    _buffObject.offset = 0;
                    ProcessBytes(v, 0, len);
                }
                else
                {
                    _buffObject.offset = 0;
                }
            }

            _transportState = TransportState.ReadBody;
        }
    }
}
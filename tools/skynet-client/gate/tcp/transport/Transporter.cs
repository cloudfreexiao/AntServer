
namespace Skynet.DotNetClient.Gate.TCP
{
    using System;
    using System.Net.Sockets;
    using Utils.Logger;
    
    
    public class Transporter
    {
        private const int HeadLength = 2;
        private readonly byte[] _headBuffer = new byte[HeadLength];

        private readonly Socket _socket;
        private readonly Protocol _protocol;
        
        internal Action onDisconnect = null;
        
        private readonly StateObject _stateObject = new StateObject();
        private TransportState _transportState;
        
        private byte[] _buffer;
        private int _bufferOffset;
        private int _pkgLength;

        public Transporter(Socket socket, Protocol protocol)
        {
            _socket = socket;
            _protocol = protocol;
            _transportState = TransportState.ReadHead;

            _bufferOffset = 0;
            _pkgLength = 0;
        }

        public void Start()
        {
            Receive();
        }

		public void Send(byte[] buffer, int length)
        {
            if (_transportState != TransportState.Closed)
            {
				_socket.BeginSend(buffer, 0, length, SocketFlags.None, new AsyncCallback(SendCallback), null);
            }
        }

        private void SendCallback(IAsyncResult asr)
        {
            if (_transportState == TransportState.Closed) 
                return;
            _socket.EndSend(asr);
        }

        private void Receive()
        {
           _socket.BeginReceive(_stateObject.buffer, 0, _stateObject.buffer.Length, SocketFlags.None, new AsyncCallback(EndReceive), _stateObject);
        }

        internal void Close()
        {
            _transportState = TransportState.Closed;
        }

        private void EndReceive(IAsyncResult asr)
        {
            if (_transportState == TransportState.Closed)
                return;
            var state = (StateObject)asr.AsyncState;
            try
            {
                var length = _socket.EndReceive(asr);
                if (length > 0)
                {
                    ProcessBytes(state.buffer, 0, length);
                    Receive();
                }
                else
                {
                    SkynetLogger.Error(Channel.NetDevice,"没有接收到任何数据 远端连接断开");

                    onDisconnect?.Invoke();
                }

            }
            catch (SocketException e)
            {
                onDisconnect?.Invoke();

                SkynetLogger.Error(Channel.NetDevice,"Socket Exception连接断开:" + e.Message.ToString());
            }
//            catch (Exception e)
//            {
//                Debug.Log("Exception" + e.Message.ToString());
//            }
        }

        private void ProcessBytes(byte[] bytes, int offset, int limit)
        {
            switch (_transportState)
            {
                case TransportState.ReadHead:
                    ReadHead(bytes, offset, limit);
                    break;
                case TransportState.ReadBody:
                    ReadBody(bytes, offset, limit);
                    break;
                case TransportState.Closed:
                    break;
                default:
                    throw new ArgumentOutOfRangeException();
            }
        }

        private void ReadHead(byte[] bytes, int offset, int limit)
        {
            var length = limit - offset;
            var headNum = HeadLength - _bufferOffset;

            if (length >= headNum)
            {
                //Write head buffer
                WriteBytes(bytes, offset, headNum, _bufferOffset, _headBuffer);
                //Get package length
				_pkgLength = _headBuffer[1] | (_headBuffer[0] << 8);

                //Init message buffer
				_buffer = new byte[_pkgLength];
				offset += headNum;
                
                _transportState = TransportState.ReadBody;

                if (offset <= limit) ProcessBytes(bytes, offset, limit);
            }
            else
            {
                WriteBytes(bytes, offset, length, _bufferOffset, _headBuffer);
                _bufferOffset += length;
            }
        }

        private void ReadBody(byte[] bytes, int offset, int limit)
        {
            var length = _pkgLength - _bufferOffset;
            if ((offset + length) <= limit)
            {
                WriteBytes(bytes, offset, length, _bufferOffset, _buffer);
                offset += length;

                //Invoke the protocol api to handle the message
                _protocol.ProcessMessage(_buffer);
                _bufferOffset = 0;
                _pkgLength = 0;

                if (_transportState != TransportState.Closed)
                    _transportState = TransportState.ReadHead;
                if (offset < limit)
                    ProcessBytes(bytes, offset, limit);
            }
            else
            {
                WriteBytes(bytes, offset, limit - offset, _bufferOffset, _buffer);
                _bufferOffset += limit - offset;
                _transportState = TransportState.ReadBody;
            }
        }

        private void WriteBytes(byte[] source, int start, int length, int offset, byte[] target)
        {
            for (var i = 0; i < length; i++)
            {
                target[offset + i] = source[start + i];
            }
        }
    }
}
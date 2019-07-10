

using UnityEngine;

namespace Skynet.DotNetClient.Gate.TCP
{
    using System;
    using System.Net.Sockets;
    
    
    public class Transporter
    {
        public const int HeadLength = 2;
        private byte[] _headBuffer = new byte[HeadLength];

        private Socket _socket;
        private Protocol _protocol;
        
        internal Action onDisconnect = null;
        
        private StateObject _stateObject = new StateObject();
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

        public void Receive()
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
            StateObject state = (StateObject)asr.AsyncState;
            try
            {
                int length = _socket.EndReceive(asr);
                if (length > 0)
                {
                    ProcessBytes(state.buffer, 0, length);
                    Receive();
                }
                else
                {
                    Debug.LogError("接受数据小于0 连接断开");

                    if (onDisconnect != null)
                        onDisconnect();
                }

            }
            catch (SocketException e)
            {
                if (onDisconnect != null)
                    onDisconnect();

                Debug.LogError("Socket Exception连接断开:" + e.Message.ToString());
            }
//            catch (Exception e)
//            {
//                Debug.Log("Exception" + e.Message.ToString());
//            }
        }

        internal void ProcessBytes(byte[] bytes, int offset, int limit)
        {
            if (_transportState == TransportState.ReadHead)
            {
                ReadHead(bytes, offset, limit);
            }
            else if (_transportState == TransportState.ReadBody)
            {
                ReadBody(bytes, offset, limit);
            }
        }

        private void ReadHead(byte[] bytes, int offset, int limit)
        {
            int length = limit - offset;
            int headNum = HeadLength - _bufferOffset;

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
            int length = _pkgLength - _bufferOffset;
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
            for (int i = 0; i < length; i++)
            {
                target[offset + i] = source[start + i];
            }
        }
    }
}
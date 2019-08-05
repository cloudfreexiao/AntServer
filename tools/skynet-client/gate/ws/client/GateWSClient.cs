namespace Skynet.DotNetClient.Gate.WS
{
    using System;
    using UnityEngine;
    using WebSocketSharp;
    using Utils;
    using Sproto;

    public class GateWSClient : IDisposable , IGateClient
    {
        public event Action<NetWorkState> _networkStateCallBack;
        
        private bool _disposed;
        private int _session;
        private Protocol _protocol;

        private EventManager _eventManager;
        private WebSocket _socket;
        private NetWorkState _netWorkState;

        private HeartBeatService _heartBeatService;

        public GateWSClient(Action<NetWorkState> networkCallBack)
        {
            _networkStateCallBack = networkCallBack;
            _eventManager = new EventManager();

            _session = 1;
            _disposed = false;
            _netWorkState = NetWorkState.Closed;
        }

        public void Connect(string host, int port)
        {
            var url = "ws://" + host + ":" + port.ToString();
            Debug.Log("URL " + url);
            _socket = new WebSocket(url);
            _socket.OnOpen += OnOpen;
            _socket.OnClose += OnClose;
          _socket.OnMessage += OnMessage;
          _socket.OnError += OnError;

          if (!_socket.IsAlive)
          {
              _socket.ConnectAsync();
          }
        }

        public void StartHeartBeatService()
        {
            //开始心跳，检测网络断开
            _heartBeatService = new HeartBeatService(10, this);
            _heartBeatService.Start();
        }

        public void Request(string proto, Action<SpObject> action)
        {
            Request(proto, null, action);
        }

        public void Request(string proto, SpObject msg, Action<SpObject> action)
        {
            if (_socket.ReadyState == WebSocketState.Open)
            {
                _eventManager.AddCallBack(_session, action);
                SpStream spStream = _protocol.Pack(proto, _session, msg);
                _socket.Send(spStream.Buffer, 0, spStream.Length);
                ++_session;
            }
        }

        public void On(string eventName, Action<SpObject> action)
        {
            _eventManager.AddOnEvent(eventName, action);
        }

        public void Disconnect()
        {
            Dispose();
        }
        
        public void ProcessMessage(SpRpcResult msg)
        {
            if (msg.ud != 0)
            {
                Debug.LogError("resp error code is: " + msg.ud);
                _eventManager.RemoveCallBack(msg.Session);
                return;
            }
			
            switch (msg.Op) {
                case SpRpcOp.Request:
                    Util.Log ("Recv Request : " + msg.Protocol.Name + ", session : " + msg.Session);
                    Util.DumpObject (msg.Data);
				
                    _eventManager.InvokeOnEvent(msg.Protocol.Name, msg.Data);
                    break;
                case SpRpcOp.Response:
                    if (msg.Protocol.Name != "heartbeat")
                    {
                        Util.Log ("Recv Response : " + msg.Protocol.Name + ", session : " + msg.Session);
                        Util.DumpObject (msg.Data);
                    }

                    _eventManager.InvokeCallBack(msg.Session, msg.Data);
                    break;
            }
        }
        
        private void OnOpen(object sender, EventArgs e)
        {
            Debug.Log("isconectd" + _socket.IsConnected );
            _protocol = new Protocol(this);
            NetWorkChanged(NetWorkState.Connected);
        }
        
        private void OnClose(object sender, CloseEventArgs e)
        {
            CloseStatusCode code = (CloseStatusCode)e.Code;
            if (code != CloseStatusCode.NoStatus && code != CloseStatusCode.Normal)
                Debug.LogError("[ERROR] " + e.Reason + " " + e.Code);
            else
                Debug.LogError( "[INFO] Closed");
            NetWorkChanged(NetWorkState.Error);
        }
        
        private void OnMessage(object sender, MessageEventArgs e)
        {
            if (e.Opcode == Opcode.Text)
            {
                _protocol.ProcessMessage(e.Data);
            }
            else if(e.Opcode == Opcode.Binary)
            {
                _protocol.ProcessMessage(e.RawData);
            }
            else if (e.Opcode == Opcode.Close)
            {
                Debug.LogError( "[OnMessage] OpCode Closed");
            }
        }
        
        private void OnError(object sender, ErrorEventArgs e)
        {
            Debug.LogError("WebSocket Has Errror" + e.Message);
            NetWorkChanged(NetWorkState.Error);
        }
        
        private void NetWorkChanged(NetWorkState state)
        {
            _netWorkState = state;

            if (_networkStateCallBack != null)
            {
                _networkStateCallBack(state);
            }
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
                // free managed resources
                if (_heartBeatService != null) {
                    _heartBeatService.Stop ();
                }
                
                if (_eventManager != null)
                {
                    _eventManager.Dispose();
                }
                
                try
                {
                    if (_socket.ReadyState == WebSocketState.Connecting
                        || _socket.ReadyState == WebSocketState.Open) 
                    {
                        _socket.Close(); 
                    }
                    _socket = null;
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
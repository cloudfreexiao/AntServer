namespace Skynet.DotNetClient.Gate.WS
{
    using System;
    using WebSocketSharp;
    using Utils.Logger;
    
    using Sproto;

    public sealed class GateWsClient : IDisposable , IGateClient
    {
        public event Action<NetWorkState> OnNetworkStateCallBack;
        
        private bool _disposed;
        private int _session;
        private Protocol _protocol;

        private readonly EventManager _eventManager;
        private WebSocket _socket;

        private HeartBeatService _heartBeatService;

        public GateWsClient(Action<NetWorkState> networkCallBack)
        {
            OnNetworkStateCallBack = networkCallBack;
            _eventManager = new EventManager();

            _session = 1;
            _disposed = false;
        }

        public void Connect(string host, int port)
        {
            var url = "ws://" + host + ":" + port.ToString();
            SkynetLogger.Info(Channel.NetDevice,"Ws Client URL " + url);
            _socket = new WebSocket(url);
            _socket.OnOpen += Open;
            _socket.OnClose += Close;
          _socket.OnMessage += Message;
          _socket.OnError += Error;

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
            if (_socket.ReadyState != WebSocketState.Open) return;
            _eventManager.AddCallBack(_session, action);
            var spStream = _protocol.Pack(proto, _session, msg);
            _socket.Send(spStream.Buffer, 0, spStream.Length);
            ++_session;
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
                SkynetLogger.Error(Channel.NetDevice,"ws client resp error code is: " + msg.ud);
                _eventManager.RemoveCallBack(msg.Session);
                return;
            }
			
            switch (msg.Op) {
                case SpRpcOp.Request:
                    SkynetLogger.Info(Channel.NetDevice, "ws client Recv Request : " + msg.Protocol.Name + ", session : " + msg.Session);
                    Utils.Util.DumpObject (msg.Data);
				
                    _eventManager.InvokeOnEvent(msg.Protocol.Name, msg.Data);
                    break;
                case SpRpcOp.Response:
                    if (msg.Protocol.Name != "heartbeat")
                    {
                        SkynetLogger.Info(Channel.NetDevice,"ws client Recv Response : " + msg.Protocol.Name + ", session : " + msg.Session);
                        Utils.Util.DumpObject (msg.Data);
                    }

                    _eventManager.InvokeCallBack(msg.Session, msg.Data);
                    break;
                case SpRpcOp.Unknown:
                    break;
                default:
                    throw new ArgumentOutOfRangeException();
            }
        }
        
        private void Open(object sender, EventArgs e)
        {
            SkynetLogger.Info(Channel.NetDevice,"ws client is connected" + _socket.IsConnected );
            _protocol = new Protocol(this);
            NetWorkChanged(NetWorkState.Connected);
        }
        
        private void Close(object sender, CloseEventArgs e)
        {
            var code = (CloseStatusCode)e.Code;
            if (code != CloseStatusCode.NoStatus && code != CloseStatusCode.Normal)
                SkynetLogger.Error(Channel.NetDevice,"[ERROR] " + e.Reason + " " + e.Code);
            else
                SkynetLogger.Error(Channel.NetDevice, "[INFO] Closed");
            NetWorkChanged(NetWorkState.Error);
        }
        
        private void Message(object sender, MessageEventArgs e)
        {
            switch (e.Opcode)
            {
                case Opcode.Text:
                    _protocol.ProcessMessage(e.Data);
                    break;
                case Opcode.Binary:
                    _protocol.ProcessMessage(e.RawData);
                    break;
                case Opcode.Close:
                    SkynetLogger.Error(Channel.NetDevice, "[OnMessage] OpCode Closed");
                    break;
                case Opcode.Cont:
                    break;
                case Opcode.Ping:
                    break;
                case Opcode.Pong:
                    break;
                default:
                    throw new ArgumentOutOfRangeException();
            }
        }
        
        public void NetWorkChanged(NetWorkState state)
        {
            OnNetworkStateCallBack?.Invoke(state);
        }
        
        private void Error(object sender, ErrorEventArgs e)
        {
            SkynetLogger.Error(Channel.NetDevice,"WebSocket Has Error" + e.Message);
            NetWorkChanged(NetWorkState.Error);
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
            // free managed resources
            _heartBeatService?.Stop ();

            _eventManager?.Dispose();

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
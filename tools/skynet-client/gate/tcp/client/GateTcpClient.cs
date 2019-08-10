
namespace Skynet.DotNetClient.Gate.TCP
{
	using System;
	using System.Net;
	using System.Net.Sockets;
	using Utils.Logger;
	using Sproto;
	
	public sealed class GateTcpClient : IGateClient,  IDisposable 
	{
		public event Action<NetWorkState> OnNetworkStateCallBack;

		private NetWorkState _netWorkState = NetWorkState.Closed;   //current network state

		private readonly EventManager _eventManager;
		private Socket _socket;
		private Protocol _protocol;
		private bool _disposed;

		private HeartBeatService _heartBeatService;

		//不能使用0，使用0默认没有Response
		private int _session;

		public GateTcpClient(Action<NetWorkState> networkCallBack)
		{
			OnNetworkStateCallBack = networkCallBack;
			_eventManager = new EventManager();

			_session = 1;
			_disposed = false;
		}
		
		public void Connect(string host, int port)
		{
			NetWorkChanged(NetWorkState.Connecting);
			IPAddress ipAddress = null;

			try
			{
				var addresses = Dns.GetHostEntry(host).AddressList;
				foreach (var item in addresses)
				{
					if (item.AddressFamily != AddressFamily.InterNetwork) continue;
					ipAddress = item;
					break;
				}
			}
			catch (Exception)
			{
				NetWorkChanged(NetWorkState.Error);
				return;
			}

			if (ipAddress == null)
			{
				throw new Exception("can not parse host : " + host);
			}

			try
			{
				_socket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
				var ie = new IPEndPoint(ipAddress, port);

				_socket.BeginConnect(ie, Connect, null);
			}
			catch (Exception e)
			{
				SkynetLogger.Error(Channel.NetDevice, $"连接服务器失败:{e.Message.ToString()}");
			}
		}

		private void Connect(IAsyncResult asr)
		{
			try
			{
				_socket.EndConnect(asr);
				_protocol = new Protocol(this, this._socket);
				NetWorkChanged(NetWorkState.Connected);
			}
			catch (Exception e)
			{
				SkynetLogger.Error(Channel.NetDevice, $"连接服务器异步结果错误:{e.Message.ToString()}");

				NetWorkChanged(NetWorkState.Error);
				Dispose();
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
			_eventManager.AddCallBack(_session, action);
			_protocol.Send(proto, _session, msg);
			++_session;
		}

		public void On(string eventName, Action<SpObject> action)
		{
			_eventManager.AddOnEvent(eventName, action);
		}

		public void NetWorkChanged(NetWorkState state)
		{
			_netWorkState = state;

			OnNetworkStateCallBack?.Invoke(state);
		}

		public void ProcessMessage(SpRpcResult msg)
		{
			if (msg.ud != 0)
			{
				SkynetLogger.Error(Channel.NetDevice,"resp error code is: " + msg.ud);
				_eventManager.RemoveCallBack(msg.Session);
				return;
			}
			
			switch (msg.Op) {
			case SpRpcOp.Request:
				SkynetLogger.Info(Channel.NetDevice, "Recv Request : " + msg.Protocol.Name + ", session : " + msg.Session);
				Utils.Util.DumpObject (msg.Data);
				
				_eventManager.InvokeOnEvent(msg.Protocol.Name, msg.Data);
				break;
			case SpRpcOp.Response:
				if (msg.Protocol.Name != "heartbeat")
				{
					SkynetLogger.Info(Channel.NetDevice,"Recv Response : " + msg.Protocol.Name + ", session : " + msg.Session);
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

		public void Disconnect()
		{
			NetWorkChanged(NetWorkState.Disconnected);
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
			// free managed resources
			_protocol?.Close();

			_heartBeatService?.Stop ();

			_eventManager?.Dispose();

			try
			{
				_socket.Shutdown(SocketShutdown.Both);
				_socket.Close();
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
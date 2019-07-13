
namespace Skynet.DotNetClient.Gate.TCP
{
	using System;
	using System.Net;
	using System.Net.Sockets;
	using UnityEngine;
	using Util;
	
	public class GateClient : IDisposable 
	{
		public event Action<NetWorkState> _networkStateCallBack;

		private NetWorkState _netWorkState = NetWorkState.CLOSED;   //current network state

		private EventManager _eventManager;
		private Socket _socket;
		private Protocol _protocol;
		private bool _disposed;

		private HeartBeatService _heartBeatService;

		//不能使用0，使用0默认没有Response
		private int _session;

		public GateClient(Action<NetWorkState> networkCallBack)
		{
			_networkStateCallBack = networkCallBack;
			_eventManager = new EventManager();

			_session = 1;
			_disposed = false;
		}
		
		public void Connect(string host, int port)
		{
			NetWorkChanged(NetWorkState.CONNECTING);
			IPAddress ipAddress = null;

			try
			{
				IPAddress[] addresses = Dns.GetHostEntry(host).AddressList;
				foreach (var item in addresses)
				{
					if (item.AddressFamily == AddressFamily.InterNetwork)
					{
						ipAddress = item;
						break;
					}
				}
			}
			catch (Exception e)
			{
				NetWorkChanged(NetWorkState.ERROR);
				return;
			}

			if (ipAddress == null)
			{
				throw new Exception("can not parse host : " + host);
			}

			try
			{
				_socket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
				IPEndPoint ie = new IPEndPoint(ipAddress, port);

				_socket.BeginConnect(ie, new AsyncCallback(OnConnect), null);
			}
			catch (Exception e)
			{
				Debug.LogError(string.Format("连接服务器失败:{0}", e.Message.ToString()));
			}
		}

		private void OnConnect(IAsyncResult asr)
		{
			try
			{
				_socket.EndConnect(asr);
				_protocol = new Protocol(this, this._socket);
				NetWorkChanged(NetWorkState.CONNECTED);
			}
			catch (Exception e)
			{
				Debug.LogError(string.Format("连接服务器异步结果错误:{0}", e.Message.ToString()));

				NetWorkChanged(NetWorkState.ERROR);
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

		private void NetWorkChanged(NetWorkState state)
		{
			_netWorkState = state;

			if (_networkStateCallBack != null)
			{
				_networkStateCallBack(state);
			}
		}

		internal void ProcessMessage(SpRpcResult msg)
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

		public void Disconnect()
		{
			NetWorkChanged(NetWorkState.DISCONNECTED);
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
				// free managed resources
				if (_protocol != null)
				{ 
					_protocol.Close();
				}

				if (_heartBeatService != null) {
					_heartBeatService.Stop ();
				}

				if (_eventManager != null)
				{
					_eventManager.Dispose();
				}

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
}
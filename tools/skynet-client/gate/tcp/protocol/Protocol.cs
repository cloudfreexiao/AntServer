
namespace Skynet.DotNetClient.Gate.TCP
{
	using UnityEngine;
	using System.Net.Sockets;
	using Sproto;
	
	public class Protocol {
		private SpStream _stream = new SpStream (1024);
		private SpRpc _rpc;

		private GateClient _client;
		private Transporter _transporter;
		private ProtocolLoader _loader;

		public Protocol(GateClient sc, Socket socket)
		{
			_client = sc;
			_transporter = new Transporter(socket, this);
			_transporter.onDisconnect = OnDisconnect;
			_transporter.Start ();

			_loader = new ProtocolLoader();
			_rpc = _loader.CreateProto();
		}
		
		internal void ProcessMessage(byte[] bytes)
		{
			SpStream stream = new SpStream (bytes, 0, bytes.Length, bytes.Length);
			SpRpcResult result = _rpc.Dispatch (stream);
			_client.ProcessMessage (result);
		}

		public void Send (string proto, int session, SpObject args) {
			_stream.Reset ();

			if (proto != "heartbeat")
			{
				Debug.Log("Send Request : " + proto + ", session : " + session);
			}

			_stream.Write ((short)0);
			_rpc.Request (proto, args, session, _stream);
			int len = _stream.Length - 2;
			_stream.Buffer[0] = (byte)((len >> 8) & 0xff);
			_stream.Buffer[1] = (byte)(len & 0xff);
			
			_transporter.Send (_stream.Buffer, _stream.Length);
		}
		
		private void OnDisconnect()
		{
			_client.Disconnect();
		}

		internal void Close()
		{
			_transporter.Close();
		}
	}
}
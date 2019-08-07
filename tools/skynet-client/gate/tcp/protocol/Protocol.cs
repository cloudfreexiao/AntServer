
namespace Skynet.DotNetClient.Gate.TCP
{
	using System.Net.Sockets;
	using Sproto;
	using Utils.Logger;
	
	public class Protocol {
		private readonly SpStream _stream = new SpStream (1024);
		private readonly SpRpc _rpc;

		private readonly IGateClient _client;
		private readonly Transporter _transporter;

		public Protocol(IGateClient sc, Socket socket)
		{
			_client = sc;
			_transporter = new Transporter(socket, this) {onDisconnect = Disconnect};
			_transporter.Start ();

			var loader = new ProtocolLoader();
			_rpc = loader.CreateRpcProto();
		}
		
		internal void ProcessMessage(byte[] bytes)
		{
			var stream = new SpStream (bytes, 0, bytes.Length, bytes.Length);
			var result = _rpc.Dispatch (stream);
			_client.ProcessMessage (result);
		}

		public void Send (string proto, int session, SpObject args) {
			_stream.Reset ();

			if (proto != "heartbeat")
			{
				SkynetLogger.Info( Channel.NetDevice, "Send Request : " + proto + ", session : " + session);
			}

			_stream.Write ((short)0);
			_rpc.Request (proto, args, session, _stream);
			var len = _stream.Length - 2;
			_stream.Buffer[0] = (byte)((len >> 8) & 0xff);
			_stream.Buffer[1] = (byte)(len & 0xff);
			
//			var mBuffer = new byte[2];
//			mBuffer[0] = (byte)((len >> 8) & 0xff);
//			mBuffer[1] = (byte)(len & 0xff);
//			
//			SkynetLogger.Error(Channel.NetDevice,"xxxxxxxx  " + len + "hex:" + Utils.Crypt.Crypt.HexEncode(mBuffer));

			_transporter.Send (_stream.Buffer, _stream.Length);
		}
		
		private void Disconnect()
		{
			_client.Disconnect();
		}

		internal void Close()
		{
			_transporter.Close();
		}
	}
}
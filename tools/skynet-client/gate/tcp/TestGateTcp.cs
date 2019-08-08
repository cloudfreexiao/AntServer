using Skynet.DotNetClient;
using Skynet.DotNetClient.Gate.TCP;
using Skynet.DotNetClient.Utils.Signals;
using Skynet.DotNetClient.Utils.Logger;
using Sproto;


public class TestGateTcp 
{
	private GateTcpClient _client;
	private AuthPackageResp _req;

	public void Run (AuthPackageResp req)
	{
		_req = req;
		
		_client = new GateTcpClient (NetWorkStateCallBack);
		//服务器验证成功标识
		_client.On("verify", VerifySucess);
		_client.Connect(_req.gate, _req.port);
	}

	private void NetWorkStateCallBack(NetWorkState state)
	{
		SkynetLogger.Info( Channel.NetDevice,"Gate Tcp NetWorkStateCallBack:" + state);
		if (state != NetWorkState.Connected) return;
		//TODO:发送 与 gate 握手消息成功后 开启 心跳操作
		var handshakeRequset = new SpObject();
		handshakeRequset.Insert("uid", _req.uid);
		handshakeRequset.Insert("secret", _req.secret);
		handshakeRequset.Insert("subid", _req.subid);

		_client.Request("handshake", handshakeRequset, (SpObject obj) =>
		{
			var role = obj["role"].AsInt();
			if (role == 0)
			{
				SpObject bornRequest = new SpObject();
				bornRequest.Insert("name", "helloworld");
				bornRequest.Insert("head", "1111111111");
				bornRequest.Insert("job", "1");
				_client.Request("born", bornRequest, (SpObject bornObj) =>
				{
					SkynetLogger.Error( Channel.NetDevice, "born resp is ok");
				} );
			}
			else
			{
				SkynetLogger.Info( Channel.NetDevice, "is has role");
			}
		});
	}

	void VerifySucess(SpObject sp)
	{
		SkynetLogger.Info( Channel.NetDevice, "is OnVerifySucess");
		
		_client.StartHeartBeatService();
		
		//TODO: 请求各模块信息
		
		//请求进入战斗服
		Join();
	}
	
	void Join()
	{
		var joinRequest = new SpObject();
		joinRequest.Insert("session", 0);
		joinRequest.Insert("model", "fight");
		
		_client.Request("join", joinRequest, (SpObject obj) =>
		{
			var udpSession = new BattleSession
			{
				session = obj["session"].AsInt(),
				host = obj["host"].AsString(),
				port = obj["port"].AsInt(),
				secret = obj["secret"].AsString()
			};

			Signals.Get<UdpSignal>().Dispatch(udpSession);
			
		} );
	}
	
	
	public void DisConnect()
	{
		_client.Disconnect();
	}
	
}

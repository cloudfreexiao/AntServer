using System;
using Skynet.DotNetClient;
using Skynet.DotNetClient.Gate.TCP;
using UnityEngine;

public class TestGateTcp 
{
	private GateClient skynetClient;
	private AuthPackageResp _req;
	
	public void Run (AuthPackageResp req)
	{
		_req = req;
		
		skynetClient = new GateClient (NetWorkStateCallBack);
		//服务器验证成功标识
		skynetClient.On("verify", OnVerifySucess);
		skynetClient.Connect(_req.gate, _req.port);
	}

	private void NetWorkStateCallBack(NetWorkState state)
	{
		Debug.Log("Gate Tcp NetWorkStateCallBack:" + state);
		if (state == NetWorkState.CONNECTED)
		{
			//TODO:发送 与 gate 握手消息成功后 开启 心跳操作
			SpObject handshake_requset = new SpObject();
			handshake_requset.Insert("uid", _req.uid);
			handshake_requset.Insert("secret", _req.secret);
			handshake_requset.Insert("subid", _req.subid);

			skynetClient.Request("handshake", handshake_requset, (SpObject obj) =>
			{
				int res = obj["res"].AsInt();
				if (res == 0)
				{
					skynetClient.StartHeartBeatService();
				}
				Debug.Log(obj["res"].AsString());
			});
		}
	}

	void OnVerifySucess(SpObject sp)
	{
		Debug.Log("is OnVerifySucess");
	}
}

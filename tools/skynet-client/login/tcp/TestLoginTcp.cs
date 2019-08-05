using System;
using Skynet.DotNetClient;
using Skynet.DotNetClient.Login.TCP;

public class TestLoginTcp
{
	private LoginClient _client;
	private readonly string _protocol = "tcp";
	public TestLoginTcp(string p)
	{
		_protocol = p;
	}
	
	public void Run (Action<int, AuthPackageResp> loginCallBack) {
		_client = new LoginClient ();

        AuthPackageReq req = new AuthPackageReq();
        req.openId = "test_cloudfreexiao_001";
        req.sdk = "2";
        req.protocol = _protocol;
        
        _client.Connect ("47.110.245.229", 15111, req, loginCallBack);
	}

	public void DisConnect()
	{
		_client.Disconnect();
	}
}

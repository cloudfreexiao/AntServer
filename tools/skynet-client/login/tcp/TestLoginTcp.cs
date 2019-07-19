using System;
using Skynet.DotNetClient;
using Skynet.DotNetClient.Login.TCP;

public class TestLoginTcp 
{
	private LoginClient skynetClient;
	private string protocol = "tcp";
	public TestLoginTcp(string p)
	{
		protocol = p;
	}
	public void Run (Action<int, AuthPackageResp> loginCallBack) {
		skynetClient = new LoginClient ();

        AuthPackageReq req = new AuthPackageReq();
        req.openId = "test_cloudfreexiao_001";
        req.sdk = "2";
        req.protocol = protocol;
        
		skynetClient.Connect ("47.110.245.229", 15111, req, loginCallBack);
	}

	public void DisConnect()
	{
		skynetClient.Disconnect();
	}
}

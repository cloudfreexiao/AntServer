using System;
using Skynet.DotNetClient.Login.TCP;

namespace Skynet.DotNetClient
{
	public class TestLoginTcp
	{
		private LoginClient _client;
		private readonly string _protocol = "tcp";

		public TestLoginTcp(string p)
		{
			_protocol = p;
		}

		public void Run(Action<int, AuthPackageResp> loginCallBack)
		{
			_client = new LoginClient();

			var req = new AuthPackageReq {openId = "test_cloudfreexiao_001", sdk = "2", protocol = _protocol};

			_client.Connect("47.110.245.229", 15111, req, loginCallBack);
		}

		public void DisConnect()
		{
			_client.Disconnect();
		}
	}

}

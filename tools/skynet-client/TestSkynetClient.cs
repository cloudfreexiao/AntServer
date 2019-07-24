using UnityEngine;

using Skynet.DotNetClient;

public class TestSkynetClient : MonoBehaviour 
{
	private TestLoginTcp _login;
	private string protocol = "tcp"; // "ws"; //"tcp";
	
	void Start () 
	{
		_login = new TestLoginTcp (protocol);
		_login.Run(ProcessLoginResp);
	}
	
	private void ProcessLoginResp(int code, AuthPackageResp resp)
	{
		_login.DisConnect();

		if(code == 200)
		{
			if (protocol == "tcp")
			{
				TestGateTcp gate = new TestGateTcp();
				gate.Run(resp);
			}
			else
			{
				TestGateWS gate = new TestGateWS();
				gate.Run(resp);
			}

		}

		_login = null;
	}
}

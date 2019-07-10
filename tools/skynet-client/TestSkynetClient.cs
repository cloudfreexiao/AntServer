using UnityEngine;

using Skynet.DotNetClient;

public class TestSkynetClient : MonoBehaviour 
{
	private TestLoginTcp _login;
	private TestGateTcp _gate;

	void Start () 
	{
		_login = new TestLoginTcp ();
		_login.Run(ProcessLoginResp);
	}
	
	private void ProcessLoginResp(int code, AuthPackageResp resp)
	{
		_login.DisConnect();

		if(code == 200)
		{
			_gate = new TestGateTcp();
			_gate.Run(resp);
		}

		_login = null;
	}
}

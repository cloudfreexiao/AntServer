using Skynet.DotNetClient;
using Skynet.DotNetClient.Utils.Signals;
using Skynet.DotNetClient.Utils.Logger;
using UnityEngine;

public class TestSkynetClient : MonoBehaviour 
{
	private TestLoginTcp _login;
	private readonly string protocol = "tcp"; // "ws"; //"tcp";

	private TestGateTcp _gateTcp;
	private TestGateWS _gateWs;
	private TestGateUdp _gateUdp;

	public void Start () 
	{
		SkynetLogger.Error(Channel.NetDevice, "++++++SkynetClient Start++++");

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
				_gateTcp = new TestGateTcp();
				_gateTcp.Run(resp);
			}
			else
			{
				_gateWs = new TestGateWS();
				_gateWs.Run(resp);
			}
			
			Signals.Get<UdpSignal>().AddListener(SignalUdp);
		}

		_login = null;
	}

	private void SignalUdp(UdpSession session)
	{
		_gateUdp = new TestGateUdp();
		_gateUdp.Run(session);
	}
	
	private void OnDestroy()
	{
		if (_login != null)
		{
			_login.DisConnect();
			_login = null;
		}

		if (_gateTcp != null)
		{
			_gateTcp.DisConnect();
			_gateTcp = null;
		}

		if (_gateWs != null)
		{
			_gateWs.DisConnect();
			_gateWs = null;
		}

		if (_gateUdp != null)
		{
			_gateUdp.DisConnect();
			_gateUdp = null;
		}
		
		SkynetLogger.Error(Channel.NetDevice, "++++++SkynetClient Destroy++++");
	}
}

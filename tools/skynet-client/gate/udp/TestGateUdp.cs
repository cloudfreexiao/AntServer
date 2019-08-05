using Skynet.DotNetClient;
using Skynet.DotNetClient.Gate.UDP;
using UnityEngine;
using Sproto;

public class TestGateUdp
{
    private GateUdpClient _client;
	
    public void Run (UdpSession udpSession)
    {
        _client = new GateUdpClient(udpSession);
        _client.Connect();
    }
    
    public void DisConnect()
    {
        _client.Disconnect();
    }
    
    
}

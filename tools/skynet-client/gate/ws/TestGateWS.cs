
using Skynet.DotNetClient;
using Skynet.DotNetClient.Gate.WS;
using UnityEngine;

public class TestGateWS 
{
    private GateWSClient _client;
    private AuthPackageResp _req;
	
    public void Run (AuthPackageResp req)
    {
        _req = req;
		
        _client = new GateWSClient (NetWorkStateCallBack);
        //服务器验证成功标识
        _client.On("verify", OnVerifySucess);
        _client.Connect(_req.gate, _req.port);
    }

    private void NetWorkStateCallBack(NetWorkState state)
    {
        Debug.Log("Gate WS NetWorkStateCallBack:" + state);
        if (state == NetWorkState.CONNECTED)
        {
            //TODO:发送 与 gate 握手消息成功后 开启 心跳操作
            SpObject handshakeRequset = new SpObject();
            handshakeRequset.Insert("uid", _req.uid);
            handshakeRequset.Insert("secret", _req.secret);
            handshakeRequset.Insert("subid", _req.subid);

            _client.Request("handshake", handshakeRequset, (SpObject obj) =>
            {
                {
                    int role = obj["role"].AsInt();
                    if (role == 0)
                    {
                        SpObject bornRequest = new SpObject();
                        bornRequest.Insert("name", "helloworld");
                        bornRequest.Insert("head", "1111111111");
                        bornRequest.Insert("job", "1");
                        _client.Request("born", bornRequest, (SpObject bornObj) =>
                        {
                            Debug.LogError("born resp is ok");
                        } );
                    }
                    else
                    {
                        Debug.Log("is has role");
                    }
                }
            });
        }
    }

    void OnVerifySucess(SpObject sp)
    {
        Debug.Log("is OnVerifySucess");
		
        _client.StartHeartBeatService();
		
        //TODO: 请求各模块信息
    }
}
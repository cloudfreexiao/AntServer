
using Skynet.DotNetClient.Gate.WS;
using Skynet.DotNetClient.Utils.Logger;
using Sproto;

namespace Skynet.DotNetClient
{

    public class TestGateWs
    {
        private GateWsClient _client;
        private AuthPackageResp _req;

        public void Run(AuthPackageResp req)
        {
            _req = req;

            _client = new GateWsClient(NetWorkStateCallBack);
            //服务器验证成功标识
            _client.On("verify", VerifySucess);
            _client.Connect(_req.gate, _req.port);
        }

        private void NetWorkStateCallBack(NetWorkState state)
        {
            SkynetLogger.Info(Channel.NetDevice, "Gate WS NetWorkStateCallBack:" + state);
            if (state == NetWorkState.Connected)
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
                            _client.Request("born", bornRequest,
                                (SpObject bornObj) => { SkynetLogger.Info(Channel.NetDevice, "born resp is ok"); });
                        }
                        else
                        {
                            SkynetLogger.Info(Channel.NetDevice, "is has role");
                        }
                    }
                });
            }
        }

        void VerifySucess(SpObject sp)
        {
            SkynetLogger.Info(Channel.NetDevice, "is OnVerifySucess");

            _client.StartHeartBeatService();
            //TODO: 请求各模块信息
        }

        public void DisConnect()
        {
            _client.Disconnect();
        }

    }
}
namespace Skynet.DotNetClient.Gate
{
    using System;
    using Sproto;
    
    public interface IGateClient
    {
        void Request(string proto, Action<SpObject> action);
        void Disconnect();
        void ProcessMessage(SpRpcResult msg);

        void NetWorkChanged(NetWorkState state);
    }
}
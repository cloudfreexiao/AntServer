namespace Skynet.DotNetClient.Gate
{
    using System;
    public interface GateClient
    {
        void Request(string proto, Action<SpObject> action);
        void Disconnect();
        void ProcessMessage(SpRpcResult msg);
    }
}
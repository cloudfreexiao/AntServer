namespace Skynet.DotNetClient.Gate
{
    using System;
    using Sproto;
    
    public interface GateClient
    {
        void Request(string proto, Action<SpObject> action);
        void Disconnect();
        void ProcessMessage(SpRpcResult msg);
    }
}
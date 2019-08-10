namespace Skynet.DotNetClient
{
    using System.IO;
    using Sproto;
    
    public class ProtocolLoader
    {
        private string _path = @"Assets/Scripts/skynet-client/proto/";
//        private string _path = @"Assets/Game/Scripts/Core/Runtime/skynet-client/proto/";
        public SpRpc CreateRpcProto()
        {
            return CreateProto("rpc");
        }
        
        public SpRpc CreateBattleProto()
        {
            return CreateProto("battle");
        }
        
        private SpRpc CreateProto(string subDir)
        {
            SpTypeManager c2SMgr;
            SpTypeManager s2CMgr;

            var c2S = _path + subDir +  "/c2s.sproto";
            using (var stream = new FileStream (c2S, FileMode.Open)) {
                c2SMgr = SpTypeManager.Import (stream);
            }

            var s2C = _path + subDir + "/s2c.sproto";
            using (var stream = new FileStream (s2C, FileMode.Open)) {
                s2CMgr = SpTypeManager.Import (stream);
            }

            var rpc = SpRpc.Create (s2CMgr, "package");
            rpc.Attach (c2SMgr);
            return rpc;
        }
    }
}
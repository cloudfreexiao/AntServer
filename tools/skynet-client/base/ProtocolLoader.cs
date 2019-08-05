namespace Skynet.DotNetClient
{
    using System.IO;
    using Sproto;
    
    public class ProtocolLoader
    {
        private string _path = @"Assets/Scripts/skynet-client/proto/";
//        private string _path = @"Assets/Game/Scripts/Core/Runtime/skynet-client/proto/";
        public SpRpc CreateProto()
        {
            SpTypeManager _c2s;
            SpTypeManager _s2c;

            var c2S = _path + "rpc/c2s.sproto";
            using (FileStream stream = new FileStream (c2S, FileMode.Open)) {
                _c2s = SpTypeManager.Import (stream);
            }

            var s2C = _path + "rpc/s2c.sproto";
            using (FileStream stream = new FileStream (s2C, FileMode.Open)) {
                _s2c = SpTypeManager.Import (stream);
            }

            SpRpc rpc = SpRpc.Create (_s2c, "package");
			rpc.Attach (_c2s);
            return rpc;
        }

    }
}
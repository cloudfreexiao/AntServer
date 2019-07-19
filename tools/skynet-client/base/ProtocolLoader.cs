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

            string c2s = _path + "proto.c2s.sproto";
            using (FileStream stream = new FileStream (c2s, FileMode.Open)) {
                _c2s = SpTypeManager.Import (stream);
            }

            string s2c = _path + "proto.s2c.sproto";
            using (FileStream stream = new FileStream (s2c, FileMode.Open)) {
                _s2c = SpTypeManager.Import (stream);
            }

            SpRpc rpc = SpRpc.Create (_s2c, "package");
			rpc.Attach (_c2s);
            return rpc;
        }

    }
}
namespace Skynet.DotNetClient.Udp
{
    using System;
    using System.Net.Sockets;
    using MiniUDP;
    
    public class UdpConnector
    {
        private readonly NetCore _netCore;

        public UdpConnector(string version, bool allowConnections)
        {
            _netCore = new NetCore(version, allowConnections);
            _netCore.PeerConnected += OnPeerConnected;
            _netCore.PeerClosed += OnPeerClosed;
        }
        
        public void Update()
        {
            _netCore.PollEvents();
        }

        private void OnPeerConnected(NetPeer peer, string token)
        {
            Console.WriteLine(peer.EndPoint + " peer connected: " + token);

            peer.PayloadReceived += PeerPayloadReceived;
            peer.NotificationReceived += PeerNotificationReceived;
        }

        private void OnPeerClosed(NetPeer peer, NetCloseReason reason, byte userKickReason, SocketError error)
        {
            
        }
        
        private void PeerPayloadReceived(NetPeer peer, byte[] data, int dataLength)
        {
            //Console.WriteLine(peer.EndPoint + " got payload: \"" + Encoding.UTF8.GetString(data, 0, dataLength) + "\"");
        }
        
        private void PeerNotificationReceived(NetPeer peer, byte[] data, int dataLength)
        {
//            Console.WriteLine(peer.EndPoint + " got notification: \"" + Encoding.UTF8.GetString(data, 0, dataLength) + "\"");
//            Console.WriteLine(
//                peer.Traffic.Ping + "ms " + 
//                (peer.Traffic.LocalLoss * 100.0f) + "% " + 
//                (peer.Traffic.RemoteLoss * 100.0f) + "% " +
//                (peer.Traffic.LocalDrop * 100.0f) + "% " +
//                (peer.Traffic.RemoteDrop * 100.0f) + "%");
        }
        
        public void Host(int port)
        {
            _netCore.Host(port);
        }
        
        public NetPeer Connect(string address, string token = "")
        {
            NetPeer host = _netCore.Connect(NetUtil.StringToEndPoint(address), token);

            host.PayloadReceived += PeerPayloadReceived;
            host.NotificationReceived += PeerNotificationReceived;

            return host;
        }
        
        public void Stop()
        {
            _netCore.Stop();
        }
        
    }
}
namespace Skynet.DotNetClient.Gate.UDP
{
    using System.Net.Sockets;
    using MiniUDP;
    using Utils.Logger;

    public class UdpConnector
    {
        private readonly IGateClient _client;
        private readonly NetCore _netCore;

        //        private readonly UdpClock _fastClock;
        private NetPeer _peer;

        
        public UdpConnector(IGateClient client, string version, bool allowConnections)
        {
            _client = client;
            // _fastClock = new UdpClock(0.01f);
            //  _fastClock.OnFixedUpdate += SendPayload;
            
            
            _netCore = new NetCore(version, allowConnections);
            _netCore.OnPeerConnected += PeerConnected;
            _netCore.OnPeerClosed += PeerClosed;
        }
        
        public void Connect(string address, string token = "")
        {
            _peer = _netCore.Connect(NetUtil.StringToEndPoint(address), token);

            _peer.PayloadReceived += PeerPayloadReceived;
//            _peer.NotificationReceived += PeerNotificationReceived;

            _client.NetWorkChanged(NetWorkState.Connected);
        }
        
        public void Stop()
        {
            _netCore.Stop();
        }
        
        public void Update()
        {
            _netCore.PollEvents();
            //_fastClock.Tick();
        }
        
        public void SendPayload(string proto, Sproto.SpObject msg)
        {
            _peer.SendPayload(proto, msg);
        }
        
        private void PeerConnected(NetPeer peer, string token)
        {
            SkynetLogger.Info(Channel.NetDevice,"udp client is connected: " + peer.IsOpen );

            peer.PayloadReceived += PeerPayloadReceived;
//            peer.NotificationReceived += PeerNotificationReceived;

//            _client.NetWorkChanged(NetWorkState.Connected);
        }

        private void PeerClosed(NetPeer peer, NetCloseReason reason, byte userKickReason, SocketError error)
        {
            SkynetLogger.Error(Channel.NetDevice,"udp error " + reason + " SocketError " + error);
            
            _client.NetWorkChanged(NetWorkState.Error);
        }
        
        private void PeerPayloadReceived(NetPeer peer, byte[] data, int dataLength)
        {
            var rpcResult =  SprotoEncoding.ParseSproto(data, dataLength);
            _client.ProcessMessage(rpcResult);
        }
        
//        private void PeerNotificationReceived(NetPeer peer, byte[] data, int dataLength)
//        {
//        }

    }
}
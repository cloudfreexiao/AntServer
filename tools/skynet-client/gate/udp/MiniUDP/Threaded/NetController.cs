/*
 *  MiniUDP - A Simple UDP Layer for Shipping and Receiving Byte Arrays
 *  Copyright (c) 2016 - Alexander Shoulson - http://ashoulson.com
 *
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, subject to the following restrictions:
 *  
 *  1. The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  2. Altered source versions must be plainly marked as such, and must not be
 *     misrepresented as being the original software.
 *  3. This notice may not be removed or altered from any source distribution.
*/

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Net;
using System.Net.Sockets;
using System.Threading;

namespace MiniUDP
{
  internal class NetController
  {
    /// <summary>
    /// Deallocates a pool-spawned event.
    /// </summary>
    internal void RecycleEvent(NetEvent evnt)
    {
      this._eventPool.Deallocate(evnt);
    }

    #region Main Thread
    // This region should only be accessed by the MAIN thread

    /// <summary>
    /// Queues a notification to be sent to the given peer.
    /// Deep-copies the user data given.
    /// </summary>
    internal void QueueNotification(NetPeer target, byte[] buffer, ushort length)
    {
      NetEvent notification =
        this.CreateEvent(
          NetEventType.Notification,
          target);

      if (notification.ReadData(buffer, 0, length) == false)
        throw new OverflowException("Data too long for notification");
      this._notificationIn.Enqueue(notification);
    }

    /// <summary>
    /// Returns the first event on the background thread's outgoing queue.
    /// </summary>
    internal bool TryReceiveEvent(out NetEvent received)
    {
      return this._eventOut.TryDequeue(out received);
    }

    /// <summary>
    /// Queues up a request to connect to an endpoint.
    /// Returns the peer representing this pending connection.
    /// </summary>
    internal NetPeer BeginConnect(IPEndPoint endpoint, string token)
    {
      NetPeer peer = new NetPeer(endpoint, token, false, 0);
      this._connectIn.Enqueue(peer);
      return peer;
    }

    /// <summary>
    /// Optionally binds our socket before starting.
    /// </summary>
    internal void Bind(int port)
    {
      this._socket.Bind(port);
    }

    /// <summary>
    /// Signals the controller to begin.
    /// </summary>
    internal void Start()
    {
      if (this._isStarted)
        throw new InvalidOperationException(
          "Controller has already been started");

      this._isStarted = true;
      this._isRunning = true;

      this.Run();
    }

    /// <summary>
    /// Signals the controller to stop updating.
    /// </summary>
    internal void Stop()
    {
      this._isRunning = false;
    }

    /// <summary>
    /// Force-closes the socket, even if we haven't stopped running.
    /// </summary>
    internal void Close()
    {
      this._socket.Close();
    }

    /// <summary>
    /// Immediately sends out a disconnect message to a peer.
    /// Can be called on either thread.
    /// </summary>
    internal void SendKick(NetPeer peer, byte reason)
    {
      _sender.SendKick(peer, NetCloseReason.KickUserReason, reason);
    }

    /// <summary>
    /// Immediately sends out a payload to a peer.
    /// Can be called on either thread.
    /// </summary>
    internal SocketError SendPayload(
      NetPeer peer,
      ushort sequence,
      byte[] data,
      ushort length)
    {
      return _sender.SendPayload(peer, sequence, data, length);
    }
    
    internal SocketError SendPayload(
      NetPeer peer,
      ushort sequence,
      string proto, 
      Sproto.SpObject msg)
    {
      return _sender.SendPayload(peer, sequence, proto, msg);
    }
    
    #endregion

    #region Background Thread
    // This region should only be accessed by the BACKGROUND thread

    private static bool IsFull // TODO: Keep a count
      =>
        false;

    private long Time => _timer.ElapsedMilliseconds;

    private readonly NetPipeline<NetPeer> _connectIn;
    private readonly NetPipeline<NetEvent> _notificationIn;
    private readonly NetPipeline<NetEvent> _eventOut;

    private readonly NetPool<NetEvent> _eventPool;
    private readonly Dictionary<IPEndPoint, NetPeer> _peers;
    private readonly Stopwatch _timer;

    private readonly NetSocket _socket;
    private readonly NetSender _sender;
    private readonly NetReceiver _receiver;
    private readonly string _version;

    private readonly Queue<NetEvent> _reusableQueue;
    private readonly List<NetPeer> _reusableList;
    private readonly byte[] _reusableBuffer;

    private long _nextTick;
    private long _nextLongTick;
    private bool _isStarted;
    private bool _isRunning;
    private readonly bool _acceptConnections;

    internal NetController(
      string ver,
      bool acceptConnections)
    {
      _connectIn = new NetPipeline<NetPeer>();
      _notificationIn = new NetPipeline<NetEvent>();
      _eventOut = new NetPipeline<NetEvent>();

      _eventPool = new NetPool<NetEvent>();
      _peers = new Dictionary<IPEndPoint, NetPeer>();
      _timer = new Stopwatch();
      _socket = new NetSocket();
      _sender = new NetSender(this._socket);
      _receiver = new NetReceiver(this._socket);

      _reusableQueue = new Queue<NetEvent>();
      _reusableList = new List<NetPeer>();
      _reusableBuffer = new byte[NetConfig.SocketBufferSize];

      _nextTick = 0;
      _nextLongTick = 0;
      _isStarted = false;
      _isRunning = false;
      _acceptConnections = acceptConnections;

      _version = ver;
    }

    /// <summary>
    /// Controller's main update loop.
    /// </summary>
    private void Run()
    {
      _timer.Start();
      while (_isRunning)
      {
        Update();
        Thread.Sleep(NetConfig.SleepTime);
      }

      // Cleanup all peers since the loop was broken
      foreach (var peer in this.GetPeers())
      {
        var sendEvent = peer.IsOpen;
        ClosePeer(peer, NetCloseReason.KickShutdown);

        if (sendEvent)
          _eventOut.Enqueue(
            CreateClosedEvent(peer, NetCloseReason.LocalShutdown));
      }
    }

    #region Peer Management
    /// <summary>
    /// Primary update logic. Iterates through and manages all peers.
    /// </summary>
    private void Update()
    {
#if DEBUG
      this._receiver.Update();
#endif

      this.ReadPackets();
      this.ReadNotifications();
      this.ReadConnectRequests();

      bool longTick;
      if (this.TickAvailable(out longTick))
      {
        foreach (NetPeer peer in this.GetPeers())
        {
          peer.Update(this.Time);
          switch (peer.Status)
          {
            case NetPeerStatus.Connecting:
              this.UpdateConnecting(peer);
              break;

            case NetPeerStatus.Connected:
              this.UpdateConnected(peer, longTick);
              break;

            case NetPeerStatus.Closed:
              this.UpdateClosed(peer);
              break;
          }
        }
      }

#if DEBUG
      this._sender.Update();
#endif
    }

    /// <summary>
    /// Returns true iff it's time for a tick, or a long tick.
    /// </summary>
    private bool TickAvailable(out bool longTick)
    {
      longTick = false;
      long currentTime = this.Time;
      if (currentTime >= this._nextTick)
      {
        this._nextTick = currentTime + NetConfig.ShortTickRate;
        if (currentTime >= this._nextLongTick)
        {
          longTick = true;
          this._nextLongTick = currentTime + NetConfig.LongTickRate;
        }
        return true;
      }
      return false;
    }

    /// <summary>
    /// Receives pending outgoing notifications from the main thread 
    /// and assigns them to their recipient peers
    /// </summary>
    private void ReadNotifications()
    {
      NetEvent notification = null;
      while (this._notificationIn.TryDequeue(out notification))
        if (notification.Peer.IsOpen)
          notification.Peer.QueueNotification(notification);
    }

    /// <summary>
    /// Read all connection requests and instantiate them as connecting peers.
    /// </summary>
    private void ReadConnectRequests()
    {
      NetPeer pending;
      while (this._connectIn.TryDequeue(out pending))
      {
        if (this._peers.ContainsKey(pending.EndPoint))
          throw new ApplicationException("Connecting to existing peer");
        if (pending.IsClosed) // User closed peer before we could connect
          continue;

        this._peers.Add(pending.EndPoint, pending);
        pending.OnReceiveOther(this.Time);
      }
    }

    /// <summary>
    /// Updates a peer that is attempting to connect.
    /// </summary>
    private void UpdateConnecting(NetPeer peer)
    {
      if (peer.GetTimeSinceRecv(this.Time) > NetConfig.ConnectionTimeOut)
      {
        this.ClosePeerSilent(peer);
        this._eventOut.Enqueue(
          this.CreateClosedEvent(peer, NetCloseReason.LocalTimeout));
        return;
      }

      this._sender.SendConnect(peer, this._version);
    }

    /// <summary>
    /// Updates a peer with an active connection.
    /// </summary>
    private void UpdateConnected(NetPeer peer, bool longTick)
    {
      if (peer.GetTimeSinceRecv(this.Time) > NetConfig.ConnectionTimeOut)
      {
        this.ClosePeer(peer, NetCloseReason.KickTimeout);
        this._eventOut.Enqueue(
          this.CreateClosedEvent(peer, NetCloseReason.LocalTimeout));
        return;
      }

      long time = this.Time;
      if (peer.HasNotifications || peer.AckRequested)
      {
        this._sender.SendNotifications(peer);
        peer.AckRequested = false;
      }
      if (longTick)
      {
        this._sender.SendPing(peer, this.Time);
      }
    }

    /// <summary>
    /// Updates a peer that has been closed.
    /// </summary>
    private void UpdateClosed(NetPeer peer)
    {
      // The peer must have been closed by the main thread, because if
      // we closed it on this thread it would have been removed immediately
      NetDebug.Assert(peer.ClosedByUser);
      this._peers.Remove(peer.EndPoint);
    }

    /// <summary>
    /// Closes a peer, sending out a best-effort notification and removing
    /// it from the dictionary of active peers.
    /// </summary>
    private void ClosePeer(
      NetPeer peer, 
      NetCloseReason reason)
    {
      if (peer.IsOpen)
        this._sender.SendKick(peer, reason);
      this.ClosePeerSilent(peer);
    }

    /// <summary>
    /// Closes a peer without sending a network notification.
    /// </summary>
    private void ClosePeerSilent(NetPeer peer)
    {
      if (peer.IsOpen)
      {
        peer.Disconnected();
        this._peers.Remove(peer.EndPoint);
      }
    }
    #endregion

    #region Packet Read
    /// <summary>
    /// Polls the socket and receives all pending packet data.
    /// </summary>
    private void ReadPackets()
    {
      for (var i = 0; i < NetConfig.MaxPacketReads; i++)
      {
        var result = 
          _receiver.TryReceive(out var source, out var buffer, out var length);
        if (NetSocket.Succeeded(result) == false)
          return;

        var type = NetEncoding.GetType(buffer);
        if (type == NetPacketType.Connect)
        {
          // We don't have a peer yet -- special case
          HandleConnectRequest(source, buffer, length);
        }
        else
        {
          if (_peers.TryGetValue(source, out var peer))
          {
            switch (type)
            {
              case NetPacketType.Accept:
                HandleConnectAccept(peer, buffer, length);
                break;

              case NetPacketType.Kick:
                HandleKick(peer, buffer, length);
                break;

              case NetPacketType.Ping:
                HandlePing(peer, buffer, length);
                break;

              case NetPacketType.Pong:
                HandlePong(peer, buffer, length);
                break;

              case NetPacketType.Carrier:
                HandleCarrier(peer, buffer, length);
                break;

              case NetPacketType.Payload:
                HandlePayload(peer, buffer, length);
                break;
            }
          }
        }
      }
    }
    #endregion

    #region Protocol Handling
    /// <summary>
    /// Handles an incoming connection request from a remote peer.
    /// </summary>
    private void HandleConnectRequest(
      IPEndPoint source, 
      byte[] buffer, 
      int length)
    {
      var success = 
        NetEncoding.ReadConnectRequest(
          buffer,
          out var ver,
          out var token);

      // Validate
      if (success == false)
      {
        NetDebug.LogError("Error reading connect request");
        return;
      }

      if (!ShouldCreatePeer(source, ver)) return;
      var curTime = Time;
      // Create and add the new peer as a client
      var peer = new NetPeer(source, token, true, curTime);
      _peers.Add(source, peer);
      peer.OnReceiveOther(curTime);

      // Accept the connection over the network
      _sender.SendAccept(peer);

      // Queue the event out to the main thread to receive the connection
      _eventOut.Enqueue(
        CreateEvent(NetEventType.PeerConnected, peer));
    }

    private void HandleConnectAccept(
      NetPeer peer,
      byte[] buffer,
      int length)
    {
      NetDebug.Assert(peer.IsClient == false, "Ignoring accept from client");
      if (peer.IsConnected || peer.IsClient)
        return;

      peer.OnReceiveOther(Time);
      peer.Connected();

      _eventOut.Enqueue(
        CreateEvent(NetEventType.PeerConnected, peer));
    }

    private void HandleKick(
      NetPeer peer,
      byte[] buffer,
      int length)
    {
      if (peer.IsClosed)
        return;

      var success = 
        NetEncoding.ReadProtocol(
          buffer,
          length,
          out var rawReason,
          out var userReason);

      // Validate
      if (success == false)
      {
        NetDebug.LogError("Error reading kick");
        return;
      }

      var closeReason = (NetCloseReason)rawReason;
      // Skip the packet if it's a bad reason (this will cause error output)
      if (NetUtil.ValidateKickReason(closeReason) == NetCloseReason.Invalid)
        return;

      peer.OnReceiveOther(Time);
      ClosePeerSilent(peer);
      _eventOut.Enqueue(
        CreateClosedEvent(peer, closeReason, userReason));
    }

    private void HandlePing(
      NetPeer peer,
      byte[] buffer,
      int length)
    {
      if (peer.IsConnected == false)
        return;

      var success =
        NetEncoding.ReadProtocol(
          buffer, 
          length, 
          out var pingSeq, 
          out var loss);

      // Validate
      if (success == false)
      {
        NetDebug.LogError("Error reading ping");
        return;
      }

      peer.OnReceivePing(Time, loss);
      _sender.SendPong(peer, pingSeq, peer.GenerateDrop());
    }

    private void HandlePong(
      NetPeer peer,
      byte[] buffer,
      int length)
    {
      if (peer.IsConnected == false)
        return;

      var success =
        NetEncoding.ReadProtocol(
          buffer, 
          length,
          out var pongSeq, 
          out var drop);

      // Validate
      if (success == false)
      {
        NetDebug.LogError("Error reading pong");
        return;
      }

      peer.OnReceivePong(this.Time, pongSeq, drop);
    }

    private void HandleCarrier(
      NetPeer peer,
      byte[] buffer,
      int length)
    {
      if (peer.IsConnected == false)
        return;

      // Read the carrier and notifications
      _reusableQueue.Clear();
      var success = 
        NetEncoding.ReadCarrier(
          CreateEvent,
          peer, 
          buffer,
          length,
          out var notificationAck,
          out var notificationSeq,
          _reusableQueue);

      // Validate
      if (success == false)
      {
        NetDebug.LogError("Error reading carrier");
        return;
      }

      var curTime = Time;
      peer.OnReceiveCarrier(curTime, notificationAck, RecycleEvent);

      // The packet contains the first sequence number. All subsequent
      // notifications have sequence numbers in order, so we just increment.
      foreach (var notification in _reusableQueue)
        if (peer.OnReceiveNotification(curTime, notificationSeq++))
          _eventOut.Enqueue(notification);
    }

    private void HandlePayload(
      NetPeer peer,
      byte[] buffer,
      int length)
    {
      if (peer.IsConnected == false)
        return;

      // Read the payload
      var success = 
        SprotoEncoding.ReadPayload(
          CreateEvent,
          peer,
          buffer,
          length,
          out var payloadSeq,
          out var et);

      // Validate
      if (success == false)
      {
        NetDebug.LogError("Error reading payload");
        return;
      }

      // Enqueue the event for processing if the peer can receive it
      if (peer.OnReceivePayload(Time, payloadSeq))
        _eventOut.Enqueue(et);
    }
    #endregion

    #region Event Allocation
    private NetEvent CreateEvent(
      NetEventType type,
      NetPeer target)
    {
      var et = _eventPool.Allocate();
      et.Initialize(
        type,
        target);
      return et;
    }

    private NetEvent CreateClosedEvent(
      NetPeer target,
      NetCloseReason closeReason,
      byte userKickReason = 0,
      SocketError socketError = SocketError.SocketError)
    {
      var et = CreateEvent(NetEventType.PeerClosed, target);
      et.CloseReason = closeReason;
      et.UserKickReason = userKickReason;
      et.SocketError = socketError;
      return et;
    }
    #endregion

    #region Misc. Helpers
    /// <summary>
    /// Whether or not we should accept a connection before consulting
    /// the application for the final verification step.
    /// 
    /// TODO: Should we create a peer anyway temporarily and include it in
    ///       cross-thread queue event so the main thread knows we rejected
    ///       a connection attempt for one of these reasons?
    /// </summary>
    private bool ShouldCreatePeer(
      IPEndPoint source,
      string ver)
    {
      if (_peers.TryGetValue(source, out var peer))
      {
        _sender.SendAccept(peer);
        return false;
      }

      if (_acceptConnections == false)
      {
        _sender.SendReject(source, NetCloseReason.RejectNotHost);
        return false;
      }

      if (IsFull)
      {
        _sender.SendReject(source, NetCloseReason.RejectFull);
        return false;
      }

      if (_version == ver) return true;
      _sender.SendReject(source, NetCloseReason.RejectVersion);
      return false;
    }

    private IEnumerable<NetPeer> GetPeers()
    {
      _reusableList.Clear();
      _reusableList.AddRange(this._peers.Values);
      return _reusableList;
    }
    #endregion

    #endregion
  }
}

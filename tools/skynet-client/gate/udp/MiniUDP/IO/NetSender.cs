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
using System.Net;
using System.Net.Sockets;

namespace MiniUDP
{
  /// <summary>
  /// Threadsafe class for writing and sending data via a socket.
  /// </summary>
  internal class NetSender
  {
    private readonly object _sendLock;
    private readonly byte[] _sendBuffer;
    private readonly NetSocket _socket;

    internal NetSender(NetSocket socket)
    {
      _sendLock = new object();
      _sendBuffer = new byte[NetConfig.SocketBufferSize];
      _socket = socket;

#if DEBUG
      _outQueue = new NetDelay();
#endif
    }

    /// <summary>
    /// Sends a kick (reject) message to an unconnected peer.
    /// </summary>
    internal SocketError SendReject(
      IPEndPoint destination,
      NetCloseReason reason)
    {
      // Skip the packet if it's a bad reason (this will cause error output)
      if (NetUtil.ValidateKickReason(reason) == NetCloseReason.Invalid)
        return SocketError.Success;

      lock (_sendLock)
      {
        var length =
        NetEncoding.PackProtocol(
          _sendBuffer,
          NetPacketType.Kick,
          (byte)reason,
          0);
        return TrySend(destination, _sendBuffer, length);
      }
    }

    /// <summary>
    /// Sends a request to connect to a remote peer.
    /// </summary>
    internal SocketError SendConnect(
      NetPeer peer,
      string version)
    {
      lock (_sendLock)
      {
        var length =
          NetEncoding.PackConnectRequest(
            _sendBuffer,
            version,
            peer.Token);
        return TrySend(peer.EndPoint, _sendBuffer, length);
      }
    }

    /// <summary>
    /// Accepts a remote request and sends an affirmative reply.
    /// </summary>
    internal SocketError SendAccept(
      NetPeer peer)
    {
      lock (_sendLock)
      {
        var length =
        NetEncoding.PackProtocol(
          _sendBuffer,
          NetPacketType.Accept,
          0,
          0);
        return this.TrySend(peer.EndPoint, this._sendBuffer, length);
      }
    }

    /// <summary>
    /// Notifies a peer that we are disconnecting. May not arrive.
    /// </summary>
    internal SocketError SendKick(
      NetPeer peer,
      NetCloseReason reason,
      byte userReason = 0)
    {
      // Skip the packet if it's a bad reason (this will cause error output)
      if (NetUtil.ValidateKickReason(reason) == NetCloseReason.Invalid)
        return SocketError.Success;

      lock (this._sendLock)
      {
        var length =
        NetEncoding.PackProtocol(
          this._sendBuffer,
          NetPacketType.Kick,
          (byte)reason,
          userReason);
        return this.TrySend(peer.EndPoint, this._sendBuffer, length);
      }
    }

    /// <summary>
    /// Sends a generic ping packet.
    /// </summary>
    internal SocketError SendPing(
      NetPeer peer,
      long curTime)
    {
      lock (_sendLock)
      {
        var length =
        NetEncoding.PackProtocol(
          _sendBuffer,
          NetPacketType.Ping,
          peer.GeneratePing(curTime),
          peer.GenerateLoss());
        return TrySend(peer.EndPoint, _sendBuffer, length);
      }
    }

    /// <summary>
    /// Sends a generic pong packet.
    /// </summary>
    internal SocketError SendPong(
      NetPeer peer,
      byte pingSeq,
      byte drop)
    {
      lock (this._sendLock)
      {
        var length =
        NetEncoding.PackProtocol(
          _sendBuffer,
          NetPacketType.Pong,
          pingSeq,
          drop);
        return TrySend(peer.EndPoint, _sendBuffer, length);
      }
    }

    /// <summary>
    /// Sends a scheduled notification message.
    /// </summary>
    internal SocketError SendNotifications(
      NetPeer peer)
    {
      lock (_sendLock)
      {
        var packedLength =
          NetEncoding.PackCarrier(
            _sendBuffer,
            peer.NotificationAck,
            peer.GetFirstSequence(),
            peer.Outgoing);
        var length = packedLength;
        return TrySend(peer.EndPoint, _sendBuffer, length);
      }
    }

    /// <summary>
    /// Immediately sends out a payload to a peer.
    /// </summary>
    internal SocketError SendPayload(
      NetPeer peer,
      ushort sequence,
      byte[] data,
      ushort dataLength)
    {
      lock (_sendLock)
      {
        var size = 
          NetEncoding.PackPayload(_sendBuffer, sequence, data, dataLength);
        return TrySend(peer.EndPoint, _sendBuffer, size);
      }
    }

    internal SocketError SendPayload(
      NetPeer peer,
      ushort sequence,
      string proto, 
      Sproto.SpObject msg)
    {
      lock (_sendLock)
      {
        var spStream = SprotoEncoding.PackPayload(proto, sequence, msg);
        return TrySend(peer.EndPoint, spStream.Buffer, (ushort)spStream.Length);
      }
    }
    
    /// <summary>
    /// Sends a packet over the network.
    /// </summary>
    private SocketError TrySend(IPEndPoint endPoint, byte[] buffer, int length)
    {
#if DEBUG
      if (NetConfig.LatencySimulation)
      {
        _outQueue.Enqueue(endPoint, buffer, length);
        return SocketError.Success;
      }
#endif
      return _socket.TrySend(endPoint, buffer, length);
    }

    #region Latency Simulation
#if DEBUG
    private readonly NetDelay _outQueue;

    internal void Update()
    {
      lock (_sendLock)
      {
        while (_outQueue.TryDequeue(out var endPoint, out var buffer, out var length))
          _socket.TrySend(endPoint, buffer, length);
      }
    }
#endif
    #endregion
  }
}

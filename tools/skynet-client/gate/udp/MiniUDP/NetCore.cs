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
using System.Text;
using System.Threading;

namespace MiniUDP
{
  public delegate void NetPeerConnectEvent(
    NetPeer peer, 
    string token);

  public delegate void NetPeerCloseEvent(
    NetPeer peer,
    NetCloseReason reason,
    byte userKickReason,
    SocketError error);
 
  public delegate void NetPeerPayloadEvent(
    NetPeer peer,
    byte[] data,
    ushort dataLength);

  public delegate void NetPeerNotificationEvent(
    NetPeer peer,
    byte[] data,
    ushort dataLength);

  public class NetCore
  {
    public event NetPeerConnectEvent OnPeerConnected;
    public event NetPeerCloseEvent OnPeerClosed;
    public event NetPeerPayloadEvent OnPeerPayload;
    public event NetPeerNotificationEvent OnPeerNotification;
    
    private readonly NetController _controller;
    private Thread _controllerThread;

    public NetCore(string version, bool allowConnections)
    {
      if (version == null)
        version = "";
      if (Encoding.UTF8.GetByteCount(version) > NetConfig.MaxVersionBytes)
        throw new ApplicationException("Version string too long");

      _controller = new NetController(version, allowConnections);
    }

    public NetPeer Connect(IPEndPoint endpoint, string token)
    {
      var peer = AddConnection(endpoint, token);
      Start();
      return peer;
    }

    public void Host(int port)
    {
      _controller.Bind(port);
      Start();
    }

    private void Start()
    {
      _controllerThread =
        new Thread(_controller.Start) {IsBackground = true};
      _controllerThread.Start();
    }

    private NetPeer AddConnection(IPEndPoint endpoint, string token)
    {
      if (token == null)
        token = "";
      if (Encoding.UTF8.GetByteCount(token) > NetConfig.MaxTokenBytes)
        throw new ApplicationException("Token string too long");

      var pending = _controller.BeginConnect(endpoint, token);
      pending.SetCore(this);
      return pending;
    }

    public void Stop(int timeout = 1000)
    {
      _controller.Stop();
      _controllerThread.Join(timeout);
      _controller.Close();
    }

    public void PollEvents()
    {
      while (_controller.TryReceiveEvent(out var et))
      {
        var peer = et.Peer;

        // No events should fire if the user closed the peer
        if (peer.ClosedByUser == false)
        {
          switch (et.EventType)
          {
            case NetEventType.PeerConnected:
              peer.SetCore(this);
              peer.OnPeerConnected();
              OnPeerConnected?.Invoke(peer, peer.Token);
              break;

            case NetEventType.PeerClosed:
              peer.OnPeerClosed(et.CloseReason, et.UserKickReason, et.SocketError);
              OnPeerClosed?.Invoke(peer, et.CloseReason, et.UserKickReason, et.SocketError);
              break;

            case NetEventType.Payload:
              peer.OnPayloadReceived(et.EncodedData, et.EncodedLength);
              OnPeerPayload?.Invoke(peer, et.EncodedData, et.EncodedLength);
              break;

            case NetEventType.Notification:
              peer.OnNotificationReceived(et.EncodedData, et.EncodedLength);
              OnPeerNotification?.Invoke(peer, et.EncodedData, et.EncodedLength);
              break;

            case NetEventType.Invalid:
              break;
            default:
              throw new NotImplementedException();
          }
        }

        _controller.RecycleEvent(et);
      }
    }

    /// <summary>
    /// Immediately sends out a disconnect message to a peer.
    /// </summary>
    internal void SendKick(NetPeer peer, byte reason)
    {
      _controller.SendKick(peer, reason);
    }

    /// <summary>
    /// Immediately sends out a payload to a peer.
    /// </summary>
    internal SocketError SendPayload(
      NetPeer peer,
      ushort sequence,
      byte[] data,
      ushort length)
    {
      return _controller.SendPayload(peer, sequence, data, length);
    }
    
    internal SocketError SendPayload(
      NetPeer peer,
      ushort sequence,
      string proto, 
      Sproto.SpObject msg)
    {
      return _controller.SendPayload(peer, sequence, proto, msg);
    }
    

    /// <summary>
    /// Adds an outgoing notification to the controller processing queue.
    /// </summary>
    internal void QueueNotification(
      NetPeer peer,
      byte[] buffer,
      ushort length)
    {
      _controller.QueueNotification(peer, buffer, length);
    }
  }
}

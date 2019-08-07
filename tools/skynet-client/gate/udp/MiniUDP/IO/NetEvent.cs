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
using System.Net.Sockets;

namespace MiniUDP
{
  /// <summary>
  /// A multipurpose class (ab)used in two ways. Used for passing messages
  /// between threads internally (called "events" in this instance) on the 
  /// pipeline queues. Also encoded/decoded over the network to pass reliable 
  /// messages to connected peers (called "notifications" in this instance).
  /// </summary>
  internal class NetEvent : INetPoolable<NetEvent>
  {
    void INetPoolable<NetEvent>.Reset() { Reset(); }

    internal byte[] EncodedData { get; private set; }

    internal ushort EncodedLength { get; private set; }

    // Buffer for encoded user data

    // Additional data for passing events around internally, not synchronized
    internal NetEventType EventType { get; private set; }
    internal NetPeer Peer { get; private set; }  // Associated peer

    // Additional data, may or may not be set
    internal NetCloseReason CloseReason { get; set; }
    internal SocketError SocketError { get; set; }
    internal byte UserKickReason { get; set; }
    internal ushort Sequence { get; set; }

    public NetEvent()
    {
      EncodedData = new byte[NetConfig.DataInitial];
      Reset();
    }

    private void Reset()
    {
      EncodedLength = 0;
      EventType = NetEventType.Invalid;
      Peer = null;

      CloseReason = NetCloseReason.Invalid;
      SocketError = SocketError.SocketError;
      UserKickReason = 0;
      Sequence = 0;
    }

    internal void Initialize(
      NetEventType type, 
      NetPeer peer)
    {
      Reset();
      EncodedLength = 0;
      EventType = type;
      Peer = peer;
    }

    internal bool ReadData(byte[] sourceBuffer, int position, ushort length)
    {
      if (length > NetConfig.DataMaximum)
      {
        NetDebug.LogError("Data too long for NetEvent");
        return false;
      }

      // Resize if necessary
      var paddedLength = length + NetConfig.DataPadding;
      if (EncodedData.Length < paddedLength)
        EncodedData = new byte[paddedLength];

      // Copy the contents
      Array.Copy(sourceBuffer, position, this.EncodedData, 0, length);
      EncodedLength = length;
      return true;
    }
  }
}

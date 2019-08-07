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

using System.Net;
using System.Net.Sockets;

namespace MiniUDP
{
  /// <summary>
  /// Since raw sockets are thread safe, we use a global socket singleton
  /// between the two threads for the sake of convenience.
  /// </summary>
  internal class NetSocket
  {
    public static bool Succeeded(SocketError error)
    {
      return (error == SocketError.Success);
    }

    public static bool Empty(SocketError error)
    {
      return (error == SocketError.NoData);
    }

    // https://msdn.microsoft.com/en-us/library/system.net.sockets.socket.aspx
    // We don't need a lock for writing, but we do for reading because polling
    // and receiving are two different non-atomic actions. In practice we
    // should only ever be reading from the socket on one thread anyway.
    private readonly object _readLock;
    private readonly Socket _rawSocket;

    internal NetSocket()
    {
      _readLock = new object();
      _rawSocket =
        new Socket(
          AddressFamily.InterNetwork,
          SocketType.Dgram,
          ProtocolType.Udp)
        {
          ReceiveBufferSize = NetConfig.SocketBufferSize, SendBufferSize = NetConfig.SocketBufferSize, Blocking = false
        };


      try
      {
        // Ignore port unreachable (connection reset by remote host)
        const uint iocIn = 0x80000000;
        const uint iocVendor = 0x18000000;
        uint SIO_UDP_CONNRESET = iocIn | iocVendor | 12;
        _rawSocket.IOControl(
          (int)SIO_UDP_CONNRESET, 
          new byte[] { 0 }, 
          null);
      }
      catch
      {
        // Not always supported
        NetDebug.LogWarning(
          "Failed to set control code for ignoring ICMP port unreachable.");
      }
    }

    internal SocketError Bind(int port)
    {
      try
      {
        _rawSocket.Bind(new IPEndPoint(IPAddress.Any, port));
      }
      catch (SocketException exception)
      {
        return exception.SocketErrorCode;
      }
      return SocketError.Success;
    }

    internal void Close()
    {
      _rawSocket.Close();
    }

    /// <summary> 
    /// Attempts to send data to endpoint via OS socket. 
    /// Returns false if the send failed.
    /// </summary>
    internal SocketError TrySend(
      IPEndPoint destination,
      byte[] buffer,
      int length)
    {
      try
      {
        NetDebug.LogMessage("Udp SendTo msg len:" + length);
        var bytesSent =
          _rawSocket.SendTo(
            buffer,
            length,
            SocketFlags.None,
            destination);
        return bytesSent == length ? SocketError.Success : SocketError.MessageSize;
      }
      catch (SocketException exception)
      {
        NetDebug.LogError("Send failed: " + exception.Message);
        NetDebug.LogError(exception.StackTrace);
        return exception.SocketErrorCode;
      }
    }

    /// <summary> 
    /// Attempts to read from OS socket. Returns false if the read fails
    /// or if there is nothing to read.
    /// </summary>
    internal SocketError TryReceive(
      out IPEndPoint source,
      byte[] destBuffer,
      out int length)
    {
      source = null;
      length = 0;

      lock (_readLock)
      {
        if (_rawSocket.Poll(0, SelectMode.SelectRead) == false)
          return SocketError.NoData;

        try
        {
          EndPoint endPoint = new IPEndPoint(IPAddress.Any, 0);

          length =
            _rawSocket.ReceiveFrom(
              destBuffer,
              destBuffer.Length,
              SocketFlags.None,
              ref endPoint);

          if (length <= 0) return SocketError.NoData;
          source = endPoint as IPEndPoint;
          return SocketError.Success;

        }
        catch (SocketException exception)
        {
          NetDebug.LogError("Receive failed: " + exception.Message);
          NetDebug.LogError(exception.StackTrace);
          return exception.SocketErrorCode;
        }
      }
    }
  }
}

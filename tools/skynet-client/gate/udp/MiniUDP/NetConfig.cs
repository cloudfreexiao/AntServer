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

namespace MiniUDP
{
  /// <summary>
  /// Reason why a peer was closed or rejected either locally or remotely.
  /// </summary>
  public enum NetCloseReason : byte
  {
    Invalid = 0,

    RejectNotHost,  // Rejected because host is not accepting connections
    RejectFull,     // Rejected because host is full
    RejectVersion,  // Rejected because host is running a different version

    KickTimeout,    // Kicked because of timeout
    KickShutdown,   // Kicked because of shutdown
    KickError,      // Kicked because of error, will NOT include socket error
    KickUserReason, // Kicked because of application, will include reason byte

    LocalTimeout,   // Dropped because of timeout
    LocalShutdown,  // Dropped because of shutdown
    LocalError,     // Dropped because of error, will include socket error
  }

  internal enum NetPacketType : byte
  {
    Invalid = 0,

    Connect,
    Accept,
    Kick,
    Ping,
    Pong,

    Carrier,
    Payload,
  }

  internal enum NetEventType : byte
  {
    Invalid = 0,

    Notification,
    Payload,

    PeerConnected, // Peer successfully connected and was accepted
    PeerClosed,    // Peer closed due to some reason (remote or local)
  }

  public static class NetConfig
  {
    #region Timing

    public const int ShortTickRate = 250;
    public const int LongTickRate = 1000;
    public const int SleepTime = 1;
    public const long ConnectionTimeOut = 15000;

    #endregion

    #region Counts
    public static int MaxPendingNotifications = 100;
    public static int MaxPacketReads = 50;
    #endregion

#if DEBUG
    #region Latency Simulation
    // Note that these are applied twice, both incoming and outgoing
    public const bool LatencySimulation = false;
    public const int MinimumLatency = 80;
    public const int MaximumLatency = 120;
    public const float LatencyTurbulence = 0.5f;
    public const float LossChance = 0.10f;
    public const float LossTurbulence = 2.0f;

    #endregion
#endif

    #region Constant Values
    /// <summary>
    /// Size of the window used for smoothing ping averages.
    /// </summary>
    public const int PingSmoothingWindow = 5;

    #region Packet
    internal const int SocketBufferSize = 2048;
    public const int DataMaximum = 1200; // Max size for a data container
    public const int DataInitial = 128; // Starting size for a new container
    public const int DataPadding = 8; // Bytes to add when resizing container

    public const int MaxVersionBytes = (1 << (8 * sizeof(byte))) - 1;
    public const int MaxTokenBytes = (1 << (8 * sizeof(byte))) - 1;
    #endregion

    internal const byte DontNotifyPeer = 0;
    internal const byte DefaultUserReason = 255;
    #endregion
  }
}

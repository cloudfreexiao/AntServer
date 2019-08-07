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

#if DEBUG
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Net;

using MiniUDP.Util;

namespace MiniUDP
{
  internal class NetDelay
  {
    private static readonly Noise _pingNoise = new Noise();
    private static readonly Noise _lossNoise = new Noise();

    private class Entry : IComparable<Entry>
    {
      public long ReleaseTime { get; }

      public IPEndPoint EndPoint { get; }
      public byte[] Data { get; }

      public Entry(
        long releaseTime,
        IPEndPoint endPoint,
        byte[] buffer,
        int length)
      {
        ReleaseTime = releaseTime;
        EndPoint = endPoint;
        Data = new byte[length];
        Array.Copy(buffer, 0, this.Data, 0, length);
      }

      public int CompareTo(Entry other)
      {
        return (int)(ReleaseTime - other.ReleaseTime);
      }
    }

//    private class EntryComparer : Comparer<Entry>
//    {
//      public override int Compare(Entry x, Entry y)
//      {
//        return (int)(x.ReleaseTime - y.ReleaseTime);
//      }
//    }

    private readonly Heap<Entry> _entries;
    private readonly Stopwatch _timer;

    public NetDelay()
    {
      _entries = new Heap<Entry>();
      _timer = new Stopwatch();
      _timer.Start();
    }

    public void Enqueue(IPEndPoint endPoint, byte[] buffer, int length)
    {
      // See if we should drop the packet
      var loss =
        _lossNoise.GetValue(
          _timer.ElapsedMilliseconds,
           NetConfig.LossTurbulence);
      if (loss < NetConfig.LossChance)
        return;

      // See if we should delay the packet
      const float latencyRange = NetConfig.MaximumLatency - NetConfig.MinimumLatency;
      var latencyNoise =
        _pingNoise.GetValue(
          _timer.ElapsedMilliseconds,
          NetConfig.LatencyTurbulence);
      var latency = 
        (int)((latencyNoise * latencyRange) + NetConfig.MinimumLatency);

      var releaseTime = _timer.ElapsedMilliseconds + latency;
      _entries.Add(new Entry(releaseTime, endPoint, buffer, length));
    }

    public bool TryDequeue(
      out IPEndPoint endPoint, 
      out byte[] buffer, 
      out int length)
    {
      endPoint = null;
      buffer = null;
      length = 0;

      if (_entries.Count <= 0) return false;
      var first = _entries.GetMin();
      if (first.ReleaseTime >= this._timer.ElapsedMilliseconds) return false;
      _entries.ExtractDominating();
      endPoint = first.EndPoint;
      buffer = first.Data;
      length = first.Data.Length;
      return true;
    }

    public void Clear()
    {
      this._entries.Clear();
    }
  }
}
#endif
namespace Skynet.DotNetClient.Gate.UDP
{
    using System;
    using System.Diagnostics;
    
    public class UdpClock
    {
        private static readonly long _start = Stopwatch.GetTimestamp();
        private static readonly double _frequency = 1.0 / (double)Stopwatch.Frequency;


        private static double Time
        {
            get
            {
                var diff = Stopwatch.GetTimestamp() - _start;
                return (double)diff * _frequency;
            }
        }

        public event Action OnFixedUpdate;

        private readonly double _updateFrequency;
        private double _lastUpdate;

        public UdpClock(double updateFrequency)
        {
            _updateFrequency = updateFrequency;
        }

        public void Start()
        { 
            _lastUpdate = UdpClock.Time;
        }

        public void Tick()
        {
            while ((_lastUpdate + _updateFrequency) <UdpClock.Time)
            {
                OnFixedUpdate?.Invoke();
                _lastUpdate += _updateFrequency;
            }
        }        
    }
}
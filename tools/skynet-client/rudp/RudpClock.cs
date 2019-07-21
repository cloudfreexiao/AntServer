namespace Skynet.DotNetClient.Rudp
{
    using System;
    using System.Diagnostics;
    
    public class RudpClock
    {
        private static readonly long _start = Stopwatch.GetTimestamp();
        private static readonly double _frequency = 1.0 / (double)Stopwatch.Frequency;


        public static double Time
        {
            get
            {
                long diff = Stopwatch.GetTimestamp() - _start;
                return (double)diff * _frequency;
            }
        }

        public event Action OnFixedUpdate;

        private readonly double _updateFrequency;
        private double _lastUpdate;

        public RudpClock(double updateFrequency)
        {
            _updateFrequency = updateFrequency;
        }

        public void Start()
        { 
            _lastUpdate = RudpClock.Time;
        }

        public void Tick()
        {
            while ((_lastUpdate + _updateFrequency) < RudpClock.Time)
            {
                if (OnFixedUpdate != null)
                    OnFixedUpdate.Invoke();
                _lastUpdate += _updateFrequency;
            }
        }        
    }
}
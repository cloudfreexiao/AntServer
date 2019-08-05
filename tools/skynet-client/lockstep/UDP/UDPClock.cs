namespace Skynet.DotNetClient.LockStep.UDP
{
    using System;
    using System.Diagnostics;
    
    public class UDPClock
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

        public UDPClock(double updateFrequency)
        {
            _updateFrequency = updateFrequency;
        }

        public void Start()
        { 
            _lastUpdate = UDPClock.Time;
        }

        public void Tick()
        {
            while ((_lastUpdate + _updateFrequency) <UDPClock.Time)
            {
                if (OnFixedUpdate != null)
                    OnFixedUpdate.Invoke();
                _lastUpdate += _updateFrequency;
            }
        }        
    }
}
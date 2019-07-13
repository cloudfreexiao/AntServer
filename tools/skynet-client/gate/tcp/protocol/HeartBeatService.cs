namespace Skynet.DotNetClient.Gate.TCP
{
	using System;
	using System.Timers;
	using UnityEngine;
	
	public class HeartBeatService
	{
		public int Timeout;

		int _interval;
		Timer _timer;
		DateTime _lastTime;

		GateClient _client;

		public HeartBeatService(int interval, GateClient sc)
		{
			_interval = interval * 1000;
			_client = sc;
		}

		public void Start()
		{
			if (_interval < 1000) 
				return;

			//start hearbeat
			_timer = new Timer();
			_timer.Interval = _interval;
			_timer.Elapsed += new ElapsedEventHandler(sendHeartBeat);
			_timer.Enabled = true;

			Timeout = 0;
			_lastTime = DateTime.Now;
		}

		public void sendHeartBeat(object source, ElapsedEventArgs e)
		{
			TimeSpan span = DateTime.Now - _lastTime;
			Timeout = (int)span.TotalMilliseconds;
			if (Timeout > _interval * 2)
			{
				Debug.Log ("timeout disconnect");
				_client.Disconnect();
			}
			else
			{
				_client.Request ("heartbeat", (SpObject obj) => { resetTimeout(); });
			}
		}

		internal void resetTimeout()
		{
			Timeout = 0;
			_lastTime = DateTime.Now;
		}
		
		public void Stop()
		{
			if (_timer != null)
			{
				_timer.Enabled = false;
				_timer.Dispose();
			}
		}
	}
}
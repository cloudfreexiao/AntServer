namespace Skynet.DotNetClient.Gate
{
	using System;
	using System.Timers;
	using Sproto;
	using Utils.Logger;
	
	public class HeartBeatService
	{
		private int Timeout;

		readonly int _interval;
		private Timer _timer;
		DateTime _lastTime;

		readonly IGateClient _client;

		public HeartBeatService(int interval, IGateClient sc)
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
			_timer.Elapsed += new ElapsedEventHandler(SendHeartBeat);
			_timer.Enabled = true;

			Timeout = 0;
			_lastTime = DateTime.Now;
		}

		private void SendHeartBeat(object source, ElapsedEventArgs e)
		{
			TimeSpan span = DateTime.Now - _lastTime;
			Timeout = (int)span.TotalMilliseconds;
			if (Timeout > _interval * 2)
			{
				SkynetLogger.Info( Channel.NetDevice, "timeout disconnect");
				_client.Disconnect();
			}
			else
			{
				_client.Request ("heartbeat", (SpObject obj) => { ResetTimeout(); });
			}
		}

		private void ResetTimeout()
		{
			Timeout = 0;
			_lastTime = DateTime.Now;
		}
		
		public void Stop()
		{
			if (_timer == null) return;
			_timer.Enabled = false;
			_timer.Dispose();
		}
	}
}
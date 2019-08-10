namespace Skynet.DotNetClient.Gate
{
	using System;
	using System.Timers;
	using Sproto;
	using Utils.Logger;
	
	public class HeartBeatService
	{
		private int _timeout;

		private readonly int _interval;
		private Timer _timer;
		private DateTime _lastTime;

		private readonly IGateClient _client;

		public HeartBeatService(int interval, IGateClient sc)
		{
			_interval = interval * 1000;
			_client = sc;
		}

		public void Start()
		{
			if (_interval < 1000) 
				return;

			//start heartbeat
			_timer = new Timer {Interval = _interval};
			_timer.Elapsed += SendHeartBeat;
			_timer.Enabled = true;

			_timeout = 0;
			_lastTime = DateTime.Now;
		}

		private void SendHeartBeat(object source, ElapsedEventArgs e)
		{
			var span = DateTime.Now - _lastTime;
			_timeout = (int)span.TotalMilliseconds;
			if (_timeout > _interval * 2)
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
			_timeout = 0;
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
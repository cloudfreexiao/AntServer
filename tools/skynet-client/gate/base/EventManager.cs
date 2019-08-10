
namespace Skynet.DotNetClient.Gate
{
    using System;
    using System.Collections.Generic;
    using Sproto;

    public class EventManager : IDisposable
    {
        private readonly Dictionary<int, Action<SpObject>> _callBackMap;
        private readonly Dictionary<string, List<Action<SpObject>>> _eventMap;

        public EventManager()
        {
            _callBackMap = new Dictionary<int, Action<SpObject>>();
            _eventMap = new Dictionary<string, List<Action<SpObject>>>();
        }

        public void AddCallBack(int id, Action<SpObject> callback)
        {
            if (id > 0 && callback != null)
            {
                _callBackMap.Add(id, callback);
            }
        }

        public void InvokeCallBack(int id, SpObject data)
        {
            if (!_callBackMap.ContainsKey(id)) return;
            _callBackMap[id].Invoke(data);
        }

        public void RemoveCallBack(int id)
        {
            _callBackMap.Remove(id);
        }
        
        public void AddOnEvent(string eventName, Action<SpObject> callback)
        {
            if (_eventMap.TryGetValue(eventName, out var list))
            {
                list.Add(callback);
            }
            else
            {
                list = new List<Action<SpObject>> {callback};
                _eventMap.Add(eventName, list);
            }
        }

        public void InvokeOnEvent(string route, SpObject msg)
        {
            if (!_eventMap.ContainsKey(route)) return;

            var list = _eventMap[route];
            foreach (var action in list) action.Invoke(msg);
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        private void Dispose(bool disposing)
        {
            _callBackMap.Clear();
            _eventMap.Clear();
        }
    }
}
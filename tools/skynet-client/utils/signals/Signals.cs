// ========================================================================================
// Signals - A typesafe, lightweight messaging lib for Unity.
// ========================================================================================
// 2017-2019, Yanko Oliveira  / http://yankooliveira.com / http://twitter.com/yankooliveira
// Special thanks to Max Knoblich for code review and Aswhin Sudhir for the anonymous 
// function asserts suggestion.
// ========================================================================================
// Inspired by StrangeIOC, minus the clutter.
// Based on http://wiki.unity3d.com/index.php/CSharpMessenger_Extended
// Converted to use strongly typed parameters and prevent use of strings as ids.
//
// Supports up to 3 parameters. More than that, and you should probably use a VO.
//
// Usage:
//    1) Define your class, eg:
//          ScoreSignal : ASignal<int> {}
//    2) Add listeners on portions that should react, eg on Awake():
//          Signals.Get<ScoreSignal>().AddListener(OnScore);
//    3) Dispatch, eg:
//          Signals.Get<ScoreSignal>().Dispatch(userScore);
//    4) Don't forget to remove the listeners upon destruction! Eg on OnDestroy():
//          Signals.Get<ScoreSignal>().RemoveListener(OnScore);
//    5) If you don't want to use global Signals, you can have your very own SignalHub
//       instance in your class
//
// ========================================================================================

using System;
using System.Collections.Generic;

namespace Skynet.DotNetClient.Utils.Signals
{
    /// <summary>
    /// Base interface for Signals
    /// </summary>
    public interface ISignal
    {
        string Hash { get; }
    }

    /// <summary>
    /// Signals main facade class for global, game-wide signals
    /// </summary>
    public static class Signals
    {
        private static readonly SignalHub _hub = new SignalHub();

        public static TSType Get<TSType>() where TSType : ISignal, new()
        {
            return _hub.Get<TSType>();
        }

        public static void AddListenerToHash(string signalHash, Action handler)
        {
            _hub.AddListenerToHash(signalHash, handler);
        }

        public static void RemoveListenerFromHash(string signalHash, Action handler)
        {
            _hub.RemoveListenerFromHash(signalHash, handler);
        }

    }

    /// <summary>
    /// A hub for Signals you can implement in your classes
    /// </summary>
    public class SignalHub
    {
        private readonly Dictionary<Type, ISignal> _signals = new Dictionary<Type, ISignal>();

        /// <summary>
        /// Getter for a signal of a given type
        /// </summary>
        /// <typeparam name="TSType">Type of signal</typeparam>
        /// <returns>The proper signal binding</returns>
        public TSType Get<TSType>() where TSType : ISignal, new()
        {
            var signalType = typeof(TSType);

            if (_signals.TryGetValue (signalType, out var signal)) 
            {
                return (TSType)signal;
            }

            return (TSType)Bind(signalType);
        }

        /// <summary>
        /// Manually provide a SignalHash and bind it to a given listener
        /// (you most likely want to use an AddListener, unless you know exactly
        /// what you are doing)
        /// </summary>
        /// <param name="signalHash">Unique hash for signal</param>
        /// <param name="handler">Callback for signal listener</param>
        public void AddListenerToHash(string signalHash, Action handler)
        {
            var signal = GetSignalByHash(signalHash);
            if(signal is ASignal aSignal)
            {
                aSignal.AddListener(handler);
            }
        }

        /// <summary>
        /// Manually provide a SignalHash and unbind it from a given listener
        /// (you most likely want to use a RemoveListener, unless you know exactly
        /// what you are doing)
        /// </summary>
        /// <param name="signalHash">Unique hash for signal</param>
        /// <param name="handler">Callback for signal listener</param>
        public void RemoveListenerFromHash(string signalHash, Action handler)
        {
            var signal = GetSignalByHash(signalHash);
            if (signal != null && signal is ASignal aSignal)
            {
                aSignal.RemoveListener(handler);
            }
        }

        private ISignal Bind(Type signalType)
        {
            if(_signals.TryGetValue(signalType, out var signal))
            {
                UnityEngine.Debug.LogError($"Signal already registered for type {signalType.ToString()}");
                return signal;
            }

            signal = (ISignal)Activator.CreateInstance(signalType);
            _signals.Add(signalType, signal);
            return signal;
        }

        private ISignal Bind<T>() where T : ISignal, new()
        {
            return Bind(typeof(T));
        }

        private ISignal GetSignalByHash(string signalHash)
        {
            foreach (var signal in _signals.Values)
            {
                if (signal.Hash == signalHash)
                {
                    return signal;
                }
            }

            return null;
        }
    }

    /// <summary>
    /// Abstract class for Signals, provides hash by type functionality
    /// </summary>
    public abstract class ABaseSignal : ISignal
    {
        private string _hash;

        /// <summary>
        /// Unique id for this signal
        /// </summary>
        public string Hash
        {
            get
            {
                if (string.IsNullOrEmpty(_hash))
                {
                    _hash = this.GetType().ToString();
                }
                return _hash;
            }
        }
    }

    /// <summary>
    /// Strongly typed messages with no parameters
    /// </summary>
    public abstract class ASignal : ABaseSignal
    {
        private Action _callback;

        /// <summary>
        /// Adds a listener to this Signal
        /// </summary>
        /// <param name="handler">Method to be called when signal is fired</param>
        public void AddListener(Action handler)
        {
            #if UNITY_EDITOR
            UnityEngine.Debug.Assert(handler.Method.GetCustomAttributes(typeof(System.Runtime.CompilerServices.CompilerGeneratedAttribute), inherit: false).Length == 0,
                "Adding anonymous delegates as Signal callbacks is not supported (you wouldn't be able to unregister them later).");
            #endif
            _callback += handler;
        }

        /// <summary>
        /// Removes a listener from this Signal
        /// </summary>
        /// <param name="handler">Method to be unregistered from signal</param>
        public void RemoveListener(Action handler)
        {
            _callback -= handler;
        }

        /// <summary>
        /// Dispatch this signal
        /// </summary>
        public void Dispatch()
        {
            _callback?.Invoke();
        }
    }

    /// <summary>
    /// Strongly typed messages with 1 parameter
    /// </summary>
    /// <typeparam name="T">Parameter type</typeparam>
    public abstract class ASignal<T>: ABaseSignal
    {
        private Action<T> _callback;

        /// <summary>
        /// Adds a listener to this Signal
        /// </summary>
        /// <param name="handler">Method to be called when signal is fired</param>
        public void AddListener(Action<T> handler)
        {
            #if UNITY_EDITOR
            UnityEngine.Debug.Assert(handler.Method.GetCustomAttributes(typeof(System.Runtime.CompilerServices.CompilerGeneratedAttribute), inherit: false).Length == 0,
                "Adding anonymous delegates as Signal callbacks is not supported (you wouldn't be able to unregister them later).");
            #endif
            _callback += handler;
        }

        /// <summary>
        /// Removes a listener from this Signal
        /// </summary>
        /// <param name="handler">Method to be unregistered from signal</param>
        public void RemoveListener(Action<T> handler)
        {
            _callback -= handler;
        }

        /// <summary>
        /// Dispatch this signal with 1 parameter
        /// </summary>
        public void Dispatch(T arg1)
        {
            _callback?.Invoke(arg1);
        }
    }

    /// <summary>
    /// Strongly typed messages with 2 parameters
    /// </summary>
    /// <typeparam name="T">First parameter type</typeparam>
    /// <typeparam name="U">Second parameter type</typeparam>
    public abstract class ASignal<T, U>: ABaseSignal
    {
        private Action<T, U> _callback;

        /// <summary>
        /// Adds a listener to this Signal
        /// </summary>
        /// <param name="handler">Method to be called when signal is fired</param>
        public void AddListener(Action<T, U> handler)
        {
            #if UNITY_EDITOR
            UnityEngine.Debug.Assert(handler.Method.GetCustomAttributes(typeof(System.Runtime.CompilerServices.CompilerGeneratedAttribute), inherit: false).Length == 0,
                "Adding anonymous delegates as Signal callbacks is not supported (you wouldn't be able to unregister them later).");
            #endif
            _callback += handler;
        }

        /// <summary>
        /// Removes a listener from this Signal
        /// </summary>
        /// <param name="handler">Method to be unregistered from signal</param>
        public void RemoveListener(Action<T, U> handler)
        {
            _callback -= handler;
        }

        /// <summary>
        /// Dispatch this signal
        /// </summary>
        public void Dispatch(T arg1, U arg2)
        {
            _callback?.Invoke(arg1, arg2);
        }
    }

    /// <summary>
    /// Strongly typed messages with 3 parameter
    /// </summary>
    /// <typeparam name="T">First parameter type</typeparam>
    /// <typeparam name="U">Second parameter type</typeparam>
    /// <typeparam name="V">Third parameter type</typeparam>
    public abstract class ASignal<T, U, V>: ABaseSignal
    {
        private Action<T, U, V> _callback;

        /// <summary>
        /// Adds a listener to this Signal
        /// </summary>
        /// <param name="handler">Method to be called when signal is fired</param>
        public void AddListener(Action<T, U, V> handler)
        {
            #if UNITY_EDITOR
            UnityEngine.Debug.Assert(handler.Method.GetCustomAttributes(typeof(System.Runtime.CompilerServices.CompilerGeneratedAttribute), inherit: false).Length == 0,
                "Adding anonymous delegates as Signal callbacks is not supported (you wouldn't be able to unregister them later).");
            #endif
            _callback += handler;
        }

        /// <summary>
        /// Removes a listener from this Signal
        /// </summary>
        /// <param name="handler">Method to be unregistered from signal</param>
        public void RemoveListener(Action<T, U, V> handler)
        {
            _callback -= handler;
        }

        /// <summary>
        /// Dispatch this signal
        /// </summary>
        public void Dispatch(T arg1, U arg2, V arg3)
        {
            _callback?.Invoke(arg1, arg2, arg3);
        }
    }
}

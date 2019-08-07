
#define UNITY_DIALOGS // Comment out to disable dialogs for fatal errors
using System;
using UnityEngine;
using System.Collections.Generic;

#if UNITY_EDITOR && UNITY_DIALOGS
using UnityEditor;
#endif

namespace Skynet.DotNetClient.Utils.Logger
{
    ///////////////////////////
    // Types
    ///////////////////////////

    [System.Flags]
    public enum Channel : uint
    {
    /// <summary>
        /// Logs from C# to do with our Lua api
        /// </summary>
        Lua             = 1 << 0,
        /// <summary>
        /// Logs directly from the Lua VM
        /// </summary>
        LuaNative       = 1 << 1,
        /// <summary>
        /// Logs to do with AI/GOAP/
        /// </summary>
        Ai              = 1 << 2,
        /// <summary>
        /// Logs to do with graphics/rendering
        /// </summary>
        Rendering       = 1 << 3,
        /// <summary>
        /// Logs to do with the physics system
        /// </summary>
        Physics         = 1 << 4,
        /// <summary>
        /// Logs to do with our UI system
        /// </summary>
        Ui              = 1 << 5,
        /// <summary>
        /// Logs about NetDevices and networks
        /// </summary>
        NetDevice       = 1 << 6,
        /// <summary>
        /// Logs to do with sound and Wwise
        /// </summary>
        Audio           = 1 << 7,
        /// <summary>
        /// Logs to do with level loading
        /// </summary>
        Loading         = 1 << 8,
        /// <summary>
        /// Logs to do with localisation
        /// </summary>
        Localisation    = 1 << 9,
        /// <summary>
        /// Logs to do with platform services
        /// </summary>
        Platform        = 1 << 10,
        /// <summary>
        /// Logs asserts
        /// </summary>
        Assert          = 1 << 11,
        /// <summary>
        /// Build/Content generation logs
        /// </summary>
        Build           = 1 << 12,
        /// <summary>
        /// Analytics logs
        /// </summary>
        Analytics       = 1 << 13,
        /// <summary>
        /// LockStep logs
        /// </summary>
        LockStep       = 1 << 14,
        
        MiniUdp        = 1 << 15,
    }

    /// <summary>
    /// The priority of the log
    /// </summary>
    public enum Priority
    {
        // Default, simple output about game
        Info,
        // Warnings that things might not be as expected
        Warning,
        // Things have already failed, alert the dev
        Error,
        // Things will not recover, bring up pop up dialog
        FatalError,
    }

    public class SkynetLogger
    {
        public const Channel kAllChannels = (Channel) ~0u;

        ///////////////////////////
        // Singleton set up 
        ///////////////////////////

        private static SkynetLogger _instance;
        private static SkynetLogger Instance => _instance ?? (_instance = new SkynetLogger());

        private SkynetLogger()
        {
            _mChannels = kAllChannels;
        }

        ///////////////////////////
        // Members
        ///////////////////////////
        private Channel _mChannels;

        public delegate void LogFunc(Channel channel, Priority priority, string message);

        public static event LogFunc OnLog;

        ///////////////////////////
        // Channel Control
        ///////////////////////////

        public static void ResetChannels()
        {
            Instance._mChannels = kAllChannels;
        }

        public static void AddChannel(Channel channelToAdd)
        {
            Instance._mChannels |= channelToAdd;
        }

        public static void RemoveChannel(Channel channelToRemove)
        {
            Instance._mChannels &= ~channelToRemove;
        }

        public static void ToggleChannel(Channel channelToToggle)
        {
            Instance._mChannels ^= channelToToggle;
        }

        private static bool IsChannelActive(Channel channelToCheck)
        {
            return (Instance._mChannels & channelToCheck) == channelToCheck;
        }

        public static void SetChannels(Channel channelsToSet)
        {
            Instance._mChannels = channelsToSet;
        }

        ///////////////////////////

        ///////////////////////////
        // Logging functions
        ///////////////////////////

        /// <summary>
        /// Standard logging function, priority will default to info level
        /// </summary>
        /// <param name="logChannel"></param>
        /// <param name="message"></param>
        public static void Log(Channel logChannel, string message)
        {
            FinalLog(logChannel, Priority.Info, message);
        }

        /// <summary>
        /// Standard logging function with specified priority
        /// </summary>
        /// <param name="logChannel"></param>
        /// <param name="priority"></param>
        /// <param name="message"></param>
        public static void Log(Channel logChannel, Priority priority, string message)
        {
            FinalLog(logChannel, priority, message);
        }

        /// <summary>
        /// Log with format args, priority will default to info level
        /// </summary>
        /// <param name="logChannel"></param>
        /// <param name="message"></param>
        /// <param name="args"></param>
        public static void Info(Channel logChannel, string message, params object[] args)
        {
            FinalLog(logChannel, Priority.Info, string.Format(message, args));
        }

        public static void Error(Channel logChannel, string message, params object[] args)
        {
            FinalLog(logChannel, Priority.Error, string.Format(message, args));
        }
        
        public static void Warning(Channel logChannel, string message, params object[] args)
        {
            FinalLog(logChannel, Priority.Warning, string.Format(message, args));
        }
        
        /// <summary>
        /// Log with format args and specified priority
        /// </summary>
        /// <param name="logChannel"></param>
        /// <param name="priority"></param>
        /// <param name="message"></param>
        /// <param name="args"></param>
        public static void Log(Channel logChannel, Priority priority, string message, params object[] args)
        {
            FinalLog(logChannel, priority, string.Format(message, args));
        }

        /// <summary>
        /// Assert that the passed in condition is true, otherwise log a fatal error
        /// </summary>
        /// <param name="condition">The condition to test</param>
        /// <param name="message">A user provided message that will be logged</param>
        public static void Assert(bool condition, string message)
        {
            if (!condition)
            {
                FinalLog(Channel.Assert, Priority.FatalError, $"Assert Failed: {message}");
            }
        }

        /// <summary>
        /// This function controls where the final string goes
        /// </summary>
        /// <param name="logChannel"></param>
        /// <param name="priority"></param>
        /// <param name="message"></param>
        private static void FinalLog(Channel logChannel, Priority priority, string message)
        {
            if (!IsChannelActive(logChannel)) return;
            // Dialog boxes can't support rich text mark up, do we won't colour the final string 
            var finalMessage = ContructFinalString(logChannel, priority, message, (priority != Priority.FatalError));

    #if UNITY_EDITOR && UNITY_DIALOGS
            // Fatal errors will create a pop up when in the editor
            if (priority == Priority.FatalError)
            {
                var ignore = EditorUtility.DisplayDialog("Fatal error", finalMessage, "Ignore", "Break");
                if (!ignore)
                {
                    Debug.Break();
                }
            }
    #endif
            // Call the correct unity logging function depending on the type of error 
            switch (priority)
            {
                case Priority.FatalError:
                case Priority.Error:
                    Debug.LogError(finalMessage);
                    break;

                case Priority.Warning:
                    Debug.LogWarning(finalMessage);
                    break;

                case Priority.Info:
                    Debug.Log(finalMessage);
                    break;
                default:
                    throw new ArgumentOutOfRangeException(nameof(priority), priority, null);
            }

            OnLog?.Invoke(logChannel, priority, finalMessage);
        }

        /// <summary>
        /// Creates the final string with colouration based on channel and priority 
        /// </summary>
        /// <param name="logChannel"></param>
        /// <param name="priority"></param>
        /// <param name="message"></param>
        /// <param name="shouldColour"></param>
        /// <returns></returns>
        private static string ContructFinalString(Channel logChannel, Priority priority, string message, bool shouldColour)
        {
            var priorityColour = _priorityToColour[priority];

            if (_channelToColour.TryGetValue(logChannel, out var channelColour))
                return !shouldColour
                    ? $"[{logChannel}] {message}"
                    : $"<b><color={channelColour}>[{logChannel}] </color></b> <color={priorityColour}>{message}</color>";
            channelColour = "black";
            Debug.LogErrorFormat("Please add colour for channel {0}", logChannel);

            return !shouldColour
                ? $"[{logChannel}] {message}"
                : $"<b><color={channelColour}>[{logChannel}] </color></b> <color={priorityColour}>{message}</color>";
        }

        /// <summary>
        /// Map a channel to a colour, using Unity's rich text system
        /// </summary>
        private static readonly Dictionary<Channel, string> _channelToColour = new Dictionary<Channel, string>
        {
            {Channel.Lua, "cyan"},
            {Channel.LuaNative, "lightblue"},
            {Channel.Ai, "blue"},
            {Channel.Rendering, "green"},
            {Channel.Physics, "yellow"},
            {Channel.Ui, "purple"},
            {Channel.NetDevice, "orange"},
            {Channel.Audio, "teal"},
            {Channel.Loading, "olive"},
            {Channel.Localisation, "brown"},
            {Channel.Platform, "red"},
            {Channel.Assert, "red"},
            {Channel.Build, "navy"},
            {Channel.Analytics, "maroon"}
        };

        /// <summary>
        /// Map a priority to a colour, using Unity's rich text system
        /// </summary>
        private static readonly Dictionary<Priority, string> _priorityToColour = new Dictionary<Priority, string>
        {
    #if UNITY_PRO_LICENSE
            { Priority.Info,        "white" },
    #else
            {Priority.Info, "black"},
    #endif
            {Priority.Warning, "orange"},
            {Priority.Error, "red"},
            {Priority.FatalError, "red"},
        };
    }

}

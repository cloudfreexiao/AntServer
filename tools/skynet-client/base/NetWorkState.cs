namespace Skynet.DotNetClient
{
    using System.ComponentModel;

    public enum NetWorkState
    {
        [Description("initial state")]
        Closed,

        [Description("connecting server")]
        Connecting,

        [Description("server connected")]
        Connected,

        [Description("disconnected with server")]
        Disconnected,

        [Description("connect timeout")]
        Timeout,

        [Description("netwrok error")]
        Error
    }
}
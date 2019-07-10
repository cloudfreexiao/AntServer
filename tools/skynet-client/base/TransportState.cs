namespace Skynet.DotNetClient
{
    public enum TransportState
    {
        ReadHead = 1,		// on read head
        ReadBody = 2,		// on read body
        Closed = 3			// connection closed, will ignore all the message and wait for clean up
    }
}
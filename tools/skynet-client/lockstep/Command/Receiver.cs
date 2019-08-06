namespace Skynet.DotNetClient.LockStep
{
    using Utils.Logger;
    
    public class Receiver
    {
        public void Action()
        {
            SkynetLogger.Info(Channel.LockStep,"Called Receiver.Action()");
        }
    }
}
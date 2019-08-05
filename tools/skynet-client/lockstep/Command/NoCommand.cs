namespace Skynet.DotNetClient.LockStep
{
    using System;
    
    [Serializable]
    public class NoCommand : Command
    {
        public NoCommand(Receiver receiver) : base(receiver)
        {
            
        }

        public NoCommand() : base()
        {
            
        }
        
        public override void Execute()
        {
            _receiver.Action();
        }
    }
}
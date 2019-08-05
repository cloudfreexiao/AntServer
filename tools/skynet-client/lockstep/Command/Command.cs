namespace Skynet.DotNetClient.LockStep
{
    using System;
    
    [Serializable]
    public abstract class Command
    {
        public int NetworkAverage { get; set; }
        public int RuntimeAverage { get; set; }

        protected Receiver _receiver;

        public Command(Receiver receiver)
        {
            _receiver = receiver;
        }

        public Command()
        {
            _receiver = new Receiver();
        }
        
        public abstract void Execute();
    }
}
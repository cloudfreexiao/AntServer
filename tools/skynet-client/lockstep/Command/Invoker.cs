namespace Skynet.DotNetClient.LockStep
{
    //https://github.com/QianMo/Unity-Design-Pattern/blob/master/Assets/Behavioral%20Patterns/Command%20Pattern/Structure/CommandStructure.cs
    public class Invoker
    {
        private Command _command;

        public void SetCommand(Command command)
        {
            _command = command;
        }

        public void ExecuteCommand()
        {
            _command.Execute();
        }
        
        
//        void Start ( )
//        {
//            // Create receiver, command, and invoker
//            Receiver receiver = new Receiver();
//            Command command = new ConcreteCommand(receiver);
//            Invoker invoker = new Invoker();
//
//            // Set and execute command
//            invoker.SetCommand(command);
//            invoker.ExecuteCommand();
//        }
    }
}
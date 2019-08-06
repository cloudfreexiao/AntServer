namespace Skynet.DotNetClient.LockStep
{
    using Utils.Logger;
    
    public class PendingCommnads
    {
        public Command[] CurrentCommands;

        //incase other players advance to the next step and send their action before we advance a step
        private Command[] _nextCommands;
        private Command[] _nextNextCommands;
        private Command[] _nextNextNextCommands;

        private int _currentCommandsCount;
        private int _nextCommandsCount;
        private int _nextNextCommandsCount;
        private int _nextNextNextCommandsCount;
        
        private readonly LockStepManager _lockStepManager;


        public PendingCommnads()
        {
            _lockStepManager = LockStepManager.Instance;
            
            
            CurrentCommands = new Command[_lockStepManager.NumberOfPlayers];
            _nextCommands = new Command[_lockStepManager.NumberOfPlayers];
            _nextNextCommands = new Command[_lockStepManager.NumberOfPlayers];
            _nextNextNextCommands = new Command[_lockStepManager.NumberOfPlayers];
		
            _currentCommandsCount = 0;
            _nextCommandsCount = 0;
            _nextNextCommandsCount = 0;
            _nextNextNextCommandsCount = 0;
        }
        
        public void NextTurn() 
        {
            //Finished processing this turns actions - clear it
            for(int i=0; i<CurrentCommands.Length; i++) 
            {
                CurrentCommands[i] = null;
            }
            Command[] swap = CurrentCommands;
		
            //last turn's actions is now this turn's actions
            CurrentCommands = _nextCommands;
            _currentCommandsCount = _nextCommandsCount;
		
            //last turn's next next actions is now this turn's next actions
            _nextCommands = _nextNextCommands;
            _nextCommandsCount = _nextNextCommandsCount;
		
            _nextNextCommands = _nextNextNextCommands;
            _nextNextCommandsCount = _nextNextNextCommandsCount;
		
            //set NextNextNextActions to the empty list
            _nextNextNextCommands = swap;
            _nextNextNextCommandsCount = 0;
        }

        public void AddCommand(Command cmd, int playerId, int currentLockStepTurn, int cmdsLockStepTurn)
        {
            //add cmd for processing later
            if(cmdsLockStepTurn == currentLockStepTurn + 1) 
            {
                //if action is for next turn, add for processing 3 turns away
                if(_nextNextNextCommands[playerId] != null) 
                {
                    //TODO: Error Handling
                    SkynetLogger.Error(Channel.LockStep,"Recieved multiple actions for player " + playerId + " for turn "  + cmdsLockStepTurn);
                }
                _nextNextNextCommands[playerId] = cmd;
                _nextNextNextCommandsCount++;
            } 
            else if(cmdsLockStepTurn == currentLockStepTurn) 
            {
                //if recieved action during our current turn
                //add for processing 2 turns away
                if(_nextNextCommands[playerId] != null) 
                {
                    //TODO: Error Handling
                    SkynetLogger.Error(Channel.LockStep,"Recieved multiple actions for player " + playerId + " for turn "  + cmdsLockStepTurn);
                }
                _nextNextCommands[playerId] = cmd;
                _nextNextCommandsCount++;
            } 
            else if(cmdsLockStepTurn == currentLockStepTurn - 1) 
            {
                //if recieved action for last turn
                //add for processing 1 turn away
                if(_nextCommands[playerId] != null) {
                    //TODO: Error Handling
                    SkynetLogger.Error(Channel.LockStep,"Recieved multiple actions for player " + playerId + " for turn "  + cmdsLockStepTurn);
                }
                _nextCommands[playerId] = cmd;
                _nextCommandsCount++;
            } 
            else 
            {
                //TODO: Error Handling
                SkynetLogger.Error(Channel.LockStep," Unexpected lockstepID recieved : " + cmdsLockStepTurn);
            }
        }
        
        public bool ReadyForNextTurn() 
        {
            if(_nextNextCommandsCount == _lockStepManager.NumberOfPlayers) {
                //if this is the 2nd turn, check if all the actions sent out on the 1st turn have been recieved
                if(_lockStepManager.LockStepTurnId == LockStepManager.FirstLockStepTurnID + 1) {
                    return true;
                }
			
                //Check if all Actions that will be processed next turn have been recieved
                if(_nextCommandsCount == _lockStepManager.NumberOfPlayers) {
                    return true;
                }
            }
		
            //if this is the 1st turn, no actions had the chance to be recieved yet
            if(_lockStepManager.LockStepTurnId == LockStepManager.FirstLockStepTurnID) {
                return true;
            }
            //if none of the conditions have been met, return false
            return false;
        }
        
        public int[] WhosNotReady() 
        {
            if(_nextNextCommandsCount == _lockStepManager.NumberOfPlayers) {
                //if this is the 2nd turn, check if all the actions sent out on the 1st turn have been recieved
                if(_lockStepManager.LockStepTurnId == LockStepManager.FirstLockStepTurnID + 1) {
                    return null;
                }
			
                //Check if all Actions that will be processed next turn have been recieved
                if(_nextCommandsCount == _lockStepManager.NumberOfPlayers) {
                    return null;
                }else {
                    return WhosNotReady (_nextCommands, _nextCommandsCount);
                }
			
            } else if(_lockStepManager.LockStepTurnId == LockStepManager.FirstLockStepTurnID) {
                //if this is the 1st turn, no actions had the chance to be recieved yet
                return null;
            } else {
                return WhosNotReady (_nextNextCommands, _nextNextCommandsCount);
            }
        }
	
        private int[] WhosNotReady(Command[] actions, int count) 
        {
            if(count < _lockStepManager.NumberOfPlayers) {
                var notReadyPlayers = new int[_lockStepManager.NumberOfPlayers - count];
			
                var index = 0;
                for(var playerId = 0; playerId < _lockStepManager.NumberOfPlayers; playerId++) {
                    if(actions[playerId] == null) {
                        notReadyPlayers[index] = playerId;
                        index++;
                    }
                }
			
                return notReadyPlayers;
            } else {
                return null;
            }
        }
        
    }
}
namespace Skynet.DotNetClient.LockStep
{
    using System;
    using System.Diagnostics;
    
    public class ConfirmedCommands
    {
        private bool[] _confirmedCurrent;
        private bool[] _confirmedPrior;
        private int _confirmedCurrentCount;
        private int _confirmedPriorCount;
        
        //Stop watches used to adjust lockstep turn length
        private Stopwatch _currentSw;
        private Stopwatch _priorSw;
        private readonly LockStepManager _lockStepManager;
        
        public ConfirmedCommands()
        {
            _lockStepManager = LockStepManager.Instance;
            _confirmedCurrent = new bool[_lockStepManager.NumberOfPlayers];
            _confirmedPrior = new bool[_lockStepManager.NumberOfPlayers];
            
            ResetArray(_confirmedCurrent);
            ResetArray (_confirmedPrior);
            
            
            _confirmedCurrentCount = 0;
            _confirmedPriorCount = 0;
		
            _currentSw = new Stopwatch();
            _priorSw = new Stopwatch();
        }
        
        	
        public void StartTimer() {
            _currentSw.Start ();
        }
        
        public int GetPriorTime() {
            return ((int)_priorSw.ElapsedMilliseconds);
        }

        public void NextTurn()
        {
            //clear prior actions
            ResetArray (_confirmedPrior);
            bool[] swap = _confirmedPrior;
            Stopwatch swapSw = _priorSw;
            
            //last turns actions is now this turns prior actions
            _confirmedPrior = _confirmedCurrent;
            _confirmedPriorCount = _confirmedCurrentCount;
            _priorSw = _currentSw;
            
            //set this turns confirmation actions to the empty array
            _confirmedCurrent = swap;
            _confirmedCurrentCount = 0;
            _currentSw = swapSw;
            _currentSw.Reset ();
        }

        public void ConfirmCommand(int confirmingPlayerId, int currentLockStepTurn, int confirmedCommandLockStepTurn)
        {
            if (confirmedCommandLockStepTurn == currentLockStepTurn)
            {
                //if current turn, add to the current Turn Confirmation
                _confirmedCurrent[confirmingPlayerId] = true;
                _confirmedCurrentCount++;
                
                //if we recieved the last confirmation, stop timer
                //this gives us the length of the longest roundtrip message
                if(_confirmedCurrentCount == _lockStepManager.NumberOfPlayers) 
                {
                    _currentSw.Stop ();
                }
            }
            else if (confirmedCommandLockStepTurn == (currentLockStepTurn - 1))
            {
                //if confirmation for prior turn, add to the prior turn confirmation
                _confirmedPrior[confirmingPlayerId] = true;
                _confirmedPriorCount++;
                //if we recieved the last confirmation, stop timer
                //this gives us the length of the longest roundtrip message
                if(_confirmedPriorCount == _lockStepManager.NumberOfPlayers) {
                    _priorSw.Stop ();
                }               
            }
            else
            {
                UnityEngine.Debug.LogError("Unexpected lockstepID Confirmed : " + confirmedCommandLockStepTurn + " from player: " + confirmingPlayerId);
            }
        }

        public bool ReadyNextTurn()
        {
            //check that the action that is going to be processed has been confirmed
            if (_confirmedCurrentCount == _lockStepManager.NumberOfPlayers)
            {
                return true;
            }
            
            //if 2nd turn, check that the 1st turns action has been confirmed
            if (_lockStepManager.LockStepTurnId == LockStepManager.FirstLockStepTurnID + 1)
            {
                return _confirmedCurrentCount == _lockStepManager.NumberOfPlayers;
            }
            
            //no action has been sent out prior to the first turn
            if (_lockStepManager.LockStepTurnId == LockStepManager.FirstLockStepTurnID)
            {
                return true;
            }
            //if none of the conditions have been met, return false
            return false;
        }

        public int[] WhosNotConfirmed()
        {
            //check that the action that is going to be processed has been confirmed
            if (_confirmedCurrentCount == _lockStepManager.NumberOfPlayers)
            {
                return null;
            }
            
            //if 2nd turn, check that the 1st turns action has been confirmed
            if(_lockStepManager.LockStepTurnId == LockStepManager.FirstLockStepTurnID + 1) 
            {
                if(_confirmedCurrentCount == _lockStepManager.NumberOfPlayers) 
                {
                    return null;
                }
                else 
                {
                    return WhosNotConfirmed (_confirmedCurrent, _confirmedCurrentCount);
                }
            }
            //no action has been sent out prior to the first turn
            if(_lockStepManager.LockStepTurnId == LockStepManager.FirstLockStepTurnID) {
                return null;
            }
		
            return WhosNotConfirmed (_confirmedPrior, _confirmedPriorCount);            
        }
        
        private int[] WhosNotConfirmed(bool[] confirmed, int confirmedCount) 
        { 
            if(confirmedCount < _lockStepManager.NumberOfPlayers) 
            {
                //the number of "not confirmed" is the number of players minus the number of "confirmed"
                var notConfirmed = new int[_lockStepManager.NumberOfPlayers - confirmedCount];
                var count = 0;
                //loop through each player and see who has not confirmed
                for(var playerId = 0; playerId < _lockStepManager.NumberOfPlayers; playerId++) 
                {
                    if(!confirmed[playerId]) 
                    {
                        //add "not confirmed" player ID to the array
                        notConfirmed[count] = playerId;
                        count++;
                    }
                }
			
                return notConfirmed;
            }
            else
            {
                return null;
            }
        }
        
        private void ResetArray(bool[] a) 
        {
            for(int i=0; i<a.Length; i++) 
            {
                a[i] = false;
            }
        }
        
    }
}
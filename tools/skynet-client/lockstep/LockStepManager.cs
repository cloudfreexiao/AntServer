using System.Text;
using UnityEngine;
using Skynet.DotNetClient.Utils.Logger;

namespace Skynet.DotNetClient.LockStep
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics;

    
    public  class LockStepManager
    {
        #region Instance
        private static readonly Lazy<LockStepManager>
            lazy =
                new Lazy<LockStepManager>
                    (() => new LockStepManager());

        public static LockStepManager Instance { get { return lazy.Value; } }

        private LockStepManager()
        {
        }
        #endregion
        
        
        #region Public Variables

        public static readonly int FirstLockStepTurnID = 0;

        public int LockStepTurnId = FirstLockStepTurnID;
        public int NumberOfPlayers = 2;
        #endregion
        
        #region Private Variables

        private PendingCommnads _pendingCommnads;
        private ConfirmedCommands _confirmedCommands;

        private Queue<Command> _commandsToSend;
        
        private bool _initialized; //indicates if we are initialized and ready for game start

        private List<string> _readyPlayers;
        private List<string> _playersConfirmedInReady;
        
        //Variables for adjusting Lockstep and GameFrame length
        private RollingAverage _networkAverage;
        private RollingAverage _runtimeAverage;
        private long _currentGameFrameRuntime; //used to find the maximum gameframe runtime in the current lockstep turn
        private Stopwatch _gameTurnSw;
        
        private int _initialLockStepTurnLength = 200; //in Milliseconds
        private int _initialGameFrameTurnLength = 50; //in Milliseconds
        private int _lockStepTurnLength;
        private int _gameFrameTurnLength = 0;
        private int _gameFramesPerLockstepTurn;
        private int _lockStepPerSecond;
        private int _gameFramesPerSecond;
	
        private int _playerIdToProcessFirst = 0; //used to rotate what player's action gets processed first
	
        private int _gameFrame = 0; //Current Game Frame number in the currect lockstep turn
        private int _accumilatedTime = 0; //the accumilated time in Milliseconds that have passed since the last time GameFrame was called

        private int _myPlayerId = 0; //self id
        
        private NetworkManager _networkManager;
        #endregion

        void Start()
        {
            _networkManager = NetworkManager.Instance;
//            _networkManager.Start();
        }
        
        #region GameStart

        public void PrepGameStart()
        {
            SkynetLogger.Info(Channel.LockStep,"----------PrepGameStart------");
            
            LockStepTurnId = FirstLockStepTurnID;
            NumberOfPlayers = _networkManager.NumberOfPlayers;
            _pendingCommnads = new PendingCommnads();
            _confirmedCommands = new ConfirmedCommands();
            _commandsToSend = new Queue<Command>();
		
            _gameTurnSw = new Stopwatch();
            _currentGameFrameRuntime = 0;
            _networkAverage = new RollingAverage(NumberOfPlayers, _initialLockStepTurnLength);
            _runtimeAverage = new RollingAverage(NumberOfPlayers, _initialGameFrameTurnLength);
		
            InitGameStart();
        }

        public void InitGameStart()
        {
            if (_initialized)
            {
                return;
            }
            
            _readyPlayers = new List<string>(NumberOfPlayers);
            _playersConfirmedInReady = new List<string>(NumberOfPlayers);
            _initialized = true;
        }

        private void CheckGameStart()
        {
            if(_playersConfirmedInReady == null) {
                UnityEngine.Debug.LogError("Unexpected null reference during game start. IsInit? " + _initialized);
            }
            else
            {
                //check if all expected players confirmed our gamestart message
                if (_playersConfirmedInReady.Count == NumberOfPlayers)
                {
                    if (_readyPlayers.Count == NumberOfPlayers)
                    {
                        UnityEngine.Debug.Log("All players are ready to start. Starting Game.");
                        //we no longer need these lists
                        _playersConfirmedInReady = null;
                        _readyPlayers = null;
                        
                        GameStart();
                    }
                }
            }
        }

        private void GameStart()
        {
            
        }
        #endregion

        #region Game Frame
        //called once per unity frame
        public void Update()
        {
            //Basically same logic as FixedUpdate, but we can scale it by adjusting FrameLength
            _accumilatedTime = _accumilatedTime + Convert.ToInt32(Time.deltaTime * 1000);
            //in case the FPS is too slow, we may need to update the game multiple times a frame
            while (_accumilatedTime > _gameFrameTurnLength)
            {
                GameFrameTurn();
                _accumilatedTime = _accumilatedTime - _gameFrameTurnLength;
            }
        }

        private void GameFrameTurn()
        {
            //first frame is used to process actions
            if (_gameFrame == 0)
            {
                if (!LockStepTurn())
                {
                    //if the lockstep turn is not ready to advance, do not run the game turn
                    return;
                }
            }
            
            //start the stop watch to determine game frame runtime performance
            _gameTurnSw.Start();
            
            //update game
            //SceneManager.Manager.TwoDPhysics.Update (GameFramesPerSecond);
//            List<IHasGameFrame> finished = new List<IHasGameFrame>();
//            foreach(IHasGameFrame obj in SceneManager.Manager.GameFrameObjects) {
//                obj.GameFrameTurn(GameFramesPerSecond);
//                if(obj.Finished) {
//                    finished.Add (obj);
//                }
//            }
//		
//            foreach(IHasGameFrame obj in finished) {
//                SceneManager.Manager.GameFrameObjects.Remove (obj);
//            }

            _gameFrame++;
            if(_gameFrame == _gameFramesPerLockstepTurn) {
                _gameFrame = 0;
            }
            
            //clear for the next frame
            _gameTurnSw.Reset();
        }

        private bool LockStepTurn() {
            UnityEngine.Debug.Log ("LockStepTurnID: " + LockStepTurnId);
            //Check if we can proceed with the next turn
            bool nextTurn = NextTurn();
            if(nextTurn) {
                SendPendingCommand ();
                //the first and second lockstep turn will not be ready to process yet
                if(LockStepTurnId >= FirstLockStepTurnID + 3) {
                    ProcessCommands ();
                }
            }
            //otherwise wait another turn to recieve all input from all players
		
            UpdateGameFrameRate();
            return nextTurn;
        }

        private bool NextTurn()
        {
            if (_confirmedCommands.ReadyNextTurn())
            {
                if (_pendingCommnads.ReadyForNextTurn())
                {
                    //increment the turn ID
                    LockStepTurnId++;
                    //move the confirmed actions to next turn
                    _confirmedCommands.NextTurn();
                    //move the pending actions to this turn
                    _pendingCommnads.NextTurn();
                    
                    return true;
                }
                else
                {
                    StringBuilder sb = new StringBuilder();
                    sb.Append ("Have not recieved player(s) actions: ");
                    foreach(int i in _pendingCommnads.WhosNotReady ()) {
                        sb.Append (i + ", ");
                    }
                    SkynetLogger.Info(Channel.LockStep, sb.ToString ());
                }
            }
            else
            {
                StringBuilder sb = new StringBuilder();
                sb.Append ("Have not recieved confirmation from player(s): ");
                foreach(int i in _pendingCommnads.WhosNotReady ()) {
                    sb.Append (i + ", ");
                }
                SkynetLogger.Info(Channel.LockStep,sb.ToString ());
            }
            return false;
        }

        private void SendPendingCommand()
        {
            var command = _commandsToSend.Count > 0 ? _commandsToSend.Dequeue() : new NoCommand();
            
            //action.NetworkAverage = Network.GetLastPing (Network.connections[0/*host player*/]);
            command.NetworkAverage = LockStepTurnId > FirstLockStepTurnID + 1 ? _confirmedCommands.GetPriorTime() : _initialLockStepTurnLength;

            command.RuntimeAverage = Convert.ToInt32(_currentGameFrameRuntime);
            //clear the current runtime average
            _currentGameFrameRuntime = 0;
            
            //add action to our own list of actions to process TODO: _myPlayerId
            _pendingCommnads.AddCommand(command, _myPlayerId, LockStepTurnId, LockStepTurnId);
            
            //start the confirmed action timer for network average
            _confirmedCommands.StartTimer ();
            //confirm our own action
            _confirmedCommands.ConfirmCommand(_myPlayerId, LockStepTurnId, LockStepTurnId);
         
            //TODO: tell other 
            //send action to all other players
//            nv.RPC("RecieveAction", RPCMode.Others, LockStepTurnId, _myPlayerId, BinarySerialization.SerializeObjectToByteArray(action));

            SkynetLogger.Info(Channel.LockStep,"Sent " + (command.GetType().Name) + " action for turn " + LockStepTurnId);
        }

        private void ProcessCommands()
        {
            //process action should be considered in runtime performance
            _gameTurnSw.Start();
            
            //Rotate the order the player actions are processed so there is no advantage given to
            //any one player
            for(int i=_playerIdToProcessFirst; i< _pendingCommnads.CurrentCommands.Length; i++) {
                _pendingCommnads.CurrentCommands[i].Execute();
                _runtimeAverage.Add (_pendingCommnads.CurrentCommands[i].RuntimeAverage, i);
                _networkAverage.Add (_pendingCommnads.CurrentCommands[i].NetworkAverage, i);
            }
		
            for(int i=0; i<_playerIdToProcessFirst; i++) {
                _pendingCommnads.CurrentCommands[i].Execute();
                _runtimeAverage.Add (_pendingCommnads.CurrentCommands[i].RuntimeAverage, i);
                _networkAverage.Add (_pendingCommnads.CurrentCommands[i].NetworkAverage, i);
            }
		
            _playerIdToProcessFirst++;
            if(_playerIdToProcessFirst >= _pendingCommnads.CurrentCommands.Length) {
                _playerIdToProcessFirst = 0;
            }
		
            //finished processing actions for this turn, stop the stopwatch
            _gameTurnSw.Stop ();
        }

        private void UpdateGameFrameRate()
        {
            _lockStepTurnLength = (_networkAverage.GetMax () * 2/*two round trips*/) + 1/*minimum of 1 ms*/;
            _gameFrameTurnLength = _runtimeAverage.GetMax ();
		
            //lockstep turn has to be at least as long as one game frame
            if(_gameFrameTurnLength > _lockStepTurnLength) {
                _lockStepTurnLength = _gameFrameTurnLength;
            }
		
            _gameFramesPerLockstepTurn = _lockStepTurnLength / _gameFrameTurnLength;
            //if gameframe turn length does not evenly divide the lockstep turn, there is extra time left after the last
            //game frame. Add one to the game frame turn length so it will consume it and recalculate the Lockstep turn length
            if(_lockStepTurnLength % _gameFrameTurnLength > 0) {
                _gameFrameTurnLength++;
                _lockStepTurnLength = _gameFramesPerLockstepTurn * _gameFrameTurnLength;
            }
		
            _lockStepPerSecond = (1000 / _lockStepTurnLength);
            if(_lockStepPerSecond == 0) { _lockStepPerSecond = 1; } //minimum per second
		
            _gameFramesPerLockstepTurn = _lockStepPerSecond * _gameFramesPerLockstepTurn;		
        }
        #endregion
    }
}
namespace Skynet.DotNetClient.LockStep
{
    using System;

    public  class NetworkManager
    {
        #region MyRegion
        private static readonly Lazy<NetworkManager>
            lazy =
                new Lazy<NetworkManager>
                    (() => new NetworkManager());

        public static NetworkManager Instance { get { return lazy.Value; } }

        private NetworkManager()
        {
        }        
        #endregion


        #region Public Variables
        public int NumberOfPlayers = 2;

        

        #endregion


        public void Start()
        {
            
        }

        void Update()
        {
            
        }
    }
}
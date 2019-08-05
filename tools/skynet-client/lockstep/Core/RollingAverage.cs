namespace Skynet.DotNetClient.LockStep
{
    public class RollingAverage
    {
        public readonly int[] currentValues; //used only for logging
	
        private readonly int[] playerAverages;
        
        public RollingAverage(int numofPlayers, int initValue) {
            playerAverages = new int[numofPlayers];
            currentValues = new int[numofPlayers];
            for(int i=0; i<numofPlayers; i++) {
                playerAverages[i] = initValue;
                currentValues[i] = initValue;
            }
        }
	
        public void Add(int newValue, int playerId) {
            if(newValue > playerAverages[playerId]) {
                //rise quickly
                playerAverages[playerId] = newValue;
            } else {
                //slowly fall down
                playerAverages[playerId] = (playerAverages[playerId] * (9) + newValue * (1)) / 10;
            }
		
            currentValues[playerId] = newValue;
        }
	
        public int GetMax() {
            int max = int.MinValue;
            foreach(int average in playerAverages) {
                if(average > max) {
                    max = average;
                }
            }
		
            return max;
        }
    }
}
namespace Skynet.DotNetClient.LockStep
{
    public interface IHasGameFrame
    {
        void GameFrameTurn(int gameFramesPerSecond);
	
        bool Finished { get; }
    }
}
public class SpArray : SpObject
{
    public SpArray(params object[] args)
    {
        mType = ArgType.Null;
        for (int i = 0; i < args.Length; i++)
        {
            Insert(i, args[i]);
        }
    }
}
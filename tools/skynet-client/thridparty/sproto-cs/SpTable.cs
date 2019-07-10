public class SpTable : SpObject
{
    public SpTable(params object[] args)
    {
        mType = ArgType.Null;
        for (int i = 0; i < args.Length; i += 2)
        {
            Insert(args[i], args[i + 1]);
        }
    }
}
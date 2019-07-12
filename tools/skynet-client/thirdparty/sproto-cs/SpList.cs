public class SpList<T> : SpObject
{
    public SpList(T[] args)
    {
        mType = ArgType.Null;
        for (int i = 0; i < args.Length; i++)
        {
            Insert(i, args[i]);
        }
    }
}
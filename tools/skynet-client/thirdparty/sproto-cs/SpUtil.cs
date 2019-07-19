namespace Sproto
{
    using System.Collections.Generic;

    public static class SpUtil
    {
        public static SpObject[] ToSpObjectArray(SpObject obj)
        {
            if (obj != null)
            {
                Dictionary<object, SpObject> table = obj.AsTable();
                if (table != null)
                {
                    SpObject[] list = new SpObject[table.Count];
                    int index = 0;
                    Dictionary<object, SpObject>.ValueCollection.Enumerator ent = table.Values.GetEnumerator();
                    while (ent.MoveNext())
                    {
                        list[index] = ent.Current;
                        index++;
                    }

                    return list;
                }
            }

            return null;
        }

        public static uint[] ToUintArray(SpObject obj)
        {
            if (obj != null)
            {
                Dictionary<object, SpObject> table = obj.AsTable();
                if (table != null)
                {
                    uint[] list = new uint[table.Count];
                    int index = 0;
                    Dictionary<object, SpObject>.ValueCollection.Enumerator ent = table.Values.GetEnumerator();
                    while (ent.MoveNext())
                    {
                        list[index] = ent.Current.AsUint();
                        index++;
                    }

                    return list;
                }
            }

            return null;
        }

        public static byte[] ToByteArray(SpObject obj)
        {
            if (obj != null)
            {
                Dictionary<object, SpObject> table = obj.AsTable();
                if (table != null)
                {
                    byte[] list = new byte[table.Count];
                    int index = 0;
                    Dictionary<object, SpObject>.ValueCollection.Enumerator ent = table.Values.GetEnumerator();
                    while (ent.MoveNext())
                    {
                        list[index] = ent.Current.AsByte();
                        index++;
                    }

                    return list;
                }
            }

            return null;
        }

        public static int[] ToIntArray(SpObject obj)
        {
            if (obj != null)
            {
                Dictionary<object, SpObject> table = obj.AsTable();
                if (table != null)
                {
                    int[] list = new int[table.Count];
                    int index = 0;
                    Dictionary<object, SpObject>.ValueCollection.Enumerator ent = table.Values.GetEnumerator();
                    while (ent.MoveNext())
                    {
                        list[index] = ent.Current.AsInt();
                        index++;
                    }

                    return list;
                }
            }

            return null;
        }

        public static long[] ToLongArray(SpObject obj)
        {
            if (obj != null)
            {
                Dictionary<object, SpObject> table = obj.AsTable();
                if (table != null)
                {
                    long[] list = new long[table.Count];
                    int index = 0;
                    Dictionary<object, SpObject>.ValueCollection.Enumerator ent = table.Values.GetEnumerator();
                    while (ent.MoveNext())
                    {
                        list[index] = ent.Current.AsLong();
                        index++;
                    }

                    return list;
                }
            }

            return null;
        }

        public static bool[] ToBoolArray(SpObject obj)
        {
            if (obj != null)
            {
                Dictionary<object, SpObject> table = obj.AsTable();
                if (table != null)
                {
                    bool[] list = new bool[table.Count];
                    int index = 0;
                    Dictionary<object, SpObject>.ValueCollection.Enumerator ent = table.Values.GetEnumerator();
                    while (ent.MoveNext())
                    {
                        list[index] = ent.Current.AsBoolean();
                        index++;
                    }

                    return list;
                }
            }

            return null;
        }

        public static string[] ToStringArray(SpObject obj)
        {
            if (obj != null)
            {
                Dictionary<object, SpObject> table = obj.AsTable();
                if (table != null)
                {
                    string[] list = new string[table.Count];
                    int index = 0;
                    Dictionary<object, SpObject>.ValueCollection.Enumerator ent = table.Values.GetEnumerator();
                    while (ent.MoveNext())
                    {
                        list[index] = ent.Current.AsString();
                        index++;
                    }

                    return list;
                }
            }

            return null;
        }
    }
}
namespace Sproto
{


    using System.Collections.Generic;
    using System;

    public class SpObject
    {
        public enum ArgType
        {
            Array,
            Table,
            Boolean,
            String,
            Int,
            Long,
            Null,
        }

        private object mValue;
        protected ArgType mType;

        public SpObject()
        {
            mValue = null;
            mType = ArgType.Null;
        }

        public SpObject(object arg)
        {
            mValue = arg;
            mType = ArgType.Null;

            if (mValue != null)
            {
                Type t = mValue.GetType();
                if (t == typeof(long))
                {
                    mType = ArgType.Long;
                }
                else if (t == typeof(uint))
                {
                    mType = ArgType.Long;
                    mValue = Convert.ToInt64(mValue);
                }
                else if (t == typeof(int))
                {
                    mType = ArgType.Int;
                }
                else if (t == typeof(byte))
                {
                    mType = ArgType.Int;
                    mValue = Convert.ToInt32(mValue);
                }
                else if (t == typeof(string))
                {
                    mType = ArgType.String;
                }
                else if (t == typeof(bool))
                {
                    mType = ArgType.Boolean;
                }
            }
        }

        public bool IsTable()
        {
            return (mType == ArgType.Table);
        }

        public Dictionary<object, SpObject> AsTable()
        {
            return mValue as Dictionary<object, SpObject>;
        }

        public SpObject[] ToArray()
        {
            return SpUtil.ToSpObjectArray(this["Array"]);
        }

        public void Insert(object key, SpObject obj)
        {
            if (IsTable() == false)
            {
                mType = ArgType.Table;
                mValue = new Dictionary<object, SpObject>();
            }

            AsTable()[key] = obj;
        }

        public void Insert(object key, object value)
        {
            if (value.GetType() == typeof(SpObject) || value.GetType().BaseType == typeof(SpObject))
                Insert(key, (SpObject) value);
            else
                Insert(key, new SpObject(value));
        }

        public void Append(SpObject obj)
        {
            if (IsTable() == false)
            {
                mType = ArgType.Table;
                mValue = new Dictionary<object, SpObject>();
            }

            Insert(AsTable().Count, obj);
        }

        public void Append(object value)
        {
            if (value.GetType() == typeof(SpObject) || value.GetType().BaseType == typeof(SpObject))
                Append((SpObject) value);
            else
                Append(new SpObject(value));
        }

        public bool IsLong()
        {
            return (mType == ArgType.Long);
        }

        public long AsLong()
        {
            if (IsLong())
                return (long) mValue;
            return Convert.ToInt64(mValue);
        }

        public uint AsUint()
        {
            if (IsLong())
                return (uint) mValue;
            return Convert.ToUInt32(mValue);
        }

        public byte AsByte()
        {
            return Convert.ToByte(mValue);
        }

        public bool IsInt()
        {
            return (mType == ArgType.Int);
        }

        public int AsInt()
        {
            return (int) mValue;
        }

        public bool IsBoolean()
        {
            return (mType == ArgType.Boolean);
        }

        public bool AsBoolean()
        {
            return (bool) mValue;
        }

        public bool IsString()
        {
            return (mType == ArgType.String);
        }

        public string AsString()
        {
            return mValue as string;
        }

        public object Value
        {
            get { return mValue; }
        }

        public SpObject this[object key]
        {
            get
            {
                if (IsTable() == false)
                    return null;
                Dictionary<object, SpObject> t = AsTable();
                if (t.ContainsKey(key) == false)
                    return null;
                return t[key];
            }
            set
            {
                if (IsTable() == false)
                {
                    return;
                }

                Dictionary<object, SpObject> t = AsTable();
                t[key] = value;
            }
        }

        public int Count
        {
            get
            {
                if (IsTable() == false)
                    return 0;
                return AsTable().Count;
            }
        }
    }

}

using System.Collections.Generic;
using System.Text;

public class SpCodec {
	public const int MAX_SIZE = 1000000;

    //private SpStream mStream;
    private SpTypeManager mTypeManager;

    public SpCodec (SpTypeManager m) {
        mTypeManager = m;
    }

	public SpStream Encode (string proto, SpObject obj) {
        return Encode (mTypeManager.GetType (proto), obj);
    }

    public bool Encode (string proto, SpObject obj, byte[] buffer) {
        return Encode (proto, obj, buffer, 0, buffer.Length);
    }

    public bool Encode (string proto, SpObject obj, byte[] buffer, int offset, int size) {
        return Encode (proto, obj, new SpStream (buffer, offset, size));
    }

    public bool Encode (string proto, SpObject obj, SpStream stream) {
        return Encode (mTypeManager.GetType (proto), obj, stream);
    }

	public SpStream Encode (SpType type, SpObject obj) {
		SpStream stream = new SpStream ();
		
		if (Encode (type, obj, stream) == false) {
			if (stream.IsOverflow ()) {
				if (stream.Position > MAX_SIZE)
					return null;
				
				int size = stream.Position;
				size = ((size + 7) / 8) * 8;
				stream = new SpStream (size);
				if (Encode (type, obj, stream) == false)
					return null;
			}
			else {
				return null;
			}
		}
		
		return stream;
	}

    public bool Encode (SpType type, SpObject obj, SpStream stream) {
        if (type == null || obj == null || stream == null)
            return false;

        //mStream = stream;
        bool success = EncodeInternal(type, obj, stream);
		return (success && stream.IsOverflow () == false);
    }

    private bool EncodeInternal(SpType type, SpObject obj, SpStream mStream)
    {
		if (mStream == null || type == null || obj == null) {
            return false;
		}

        // buildin type decoding should not be here
		if (mTypeManager.IsBuildinType (type)) {
			return false;
		}

        int begin = mStream.Position;

        // fn. will be update later
        short fn = 0;
        mStream.Write (fn);

		List<KeyValuePair<SpObject, SpField>> objs = new List<KeyValuePair<SpObject, SpField>> ();
        int current_tag = -1;
		
		Dictionary<int, SpField>.ValueCollection.Enumerator en = type.Fields.Values.GetEnumerator ();
		while (en.MoveNext ()) {
			SpField f = en.Current;

			if (f == null) {
				return false;
			}

            SpObject o = obj[f.Name];
            if (o == null || IsTypeMatch (f, o) == false)
                continue;

			if (f.Tag <= current_tag) {
				return false;
			}

            if (f.Tag - current_tag > 1) {
                mStream.Write ((short)(2 * (f.Tag - current_tag - 1) - 1));
                fn++;
            }

            bool standalone = true;
            if (f.IsTable == false) {
                if (f.Type == mTypeManager.Boolean) {
                    int value = o.AsBoolean () ? 1 : 0;
                    mStream.Write ((short)((value + 1) * 2));
                    standalone = false;

               }
                else if (f.Type == mTypeManager.Integer) {
                    long value = o.AsLong();
                    if (value >= 0 && value < 0x7fff) {
                        mStream.Write ((short)((value + 1) * 2));
						standalone = false;
                   }
                }
            }

			if (standalone) {
                objs.Add (new KeyValuePair<SpObject, SpField> (o, f));
                mStream.Write ((short)0);
            }

            fn++;
            current_tag = f.Tag;
        }
		
		List<KeyValuePair<SpObject, SpField>>.Enumerator e = objs.GetEnumerator ();
		while (e.MoveNext ()) {
			KeyValuePair<SpObject, SpField> entry = e.Current;

            if (entry.Value.IsTable) {
                int array_begin = mStream.Position;
                int size = 0;
                mStream.Write (size);

				if (entry.Value.Type == mTypeManager.Integer) {
                   byte len = 4;

					Dictionary<object, SpObject>.Enumerator enumerator = entry.Key.AsTable ().GetEnumerator ();
					while (enumerator.MoveNext ()) {
						SpObject o = enumerator.Current.Value;
                        if (o.IsLong ()) {
                            len = 8;
                            break;
                        }
                    }

                    mStream.Write (len);
					enumerator = entry.Key.AsTable ().GetEnumerator ();
					while (enumerator.MoveNext ()) {
						SpObject o = enumerator.Current.Value;
                        if (len == 4) {
                            mStream.Write (o.AsInt ());
                        }
                        else {
                            mStream.Write (o.AsLong ());
                        }
                    }
                }
				else if (entry.Value.Type == mTypeManager.Boolean) {
					Dictionary<object, SpObject>.Enumerator enumerator = entry.Key.AsTable ().GetEnumerator ();
					while (enumerator.MoveNext ()) {
						SpObject o = enumerator.Current.Value;
                        mStream.Write ((byte)(o.AsBoolean () ? 1 : 0));
                    }
                }
				else if (entry.Value.Type == mTypeManager.String) {
					Dictionary<object, SpObject>.Enumerator enumerator = entry.Key.AsTable ().GetEnumerator ();
					while (enumerator.MoveNext ()) {
						SpObject o = enumerator.Current.Value;
                        byte[] b = Encoding.UTF8.GetBytes (o.AsString ());
                        mStream.Write (b.Length);
                        mStream.Write (b);
                    }
                }
				else {
					
					Dictionary<object, SpObject>.Enumerator enumerator = entry.Key.AsTable ().GetEnumerator ();
					while (enumerator.MoveNext ()) {
						SpObject o = enumerator.Current.Value;

                        int obj_begin = mStream.Position;
                        int obj_size = 0;
                        mStream.Write (obj_size);

                        if (EncodeInternal(entry.Value.Type, o, mStream) == false)
                        {
							return false;
						}

                        int obj_end = mStream.Position;
                        obj_size = (int)(obj_end - obj_begin - 4);
                        mStream.Position = obj_begin;
                        mStream.Write (obj_size);
                        mStream.Position = obj_end;
					}
                }

                int array_end = mStream.Position;
                size = (int)(array_end - array_begin - 4);
                mStream.Position = array_begin;
                mStream.Write (size);
                mStream.Position = array_end;
            }
            else {
                if (entry.Key.IsString ()) {
					byte[] b = Encoding.UTF8.GetBytes (entry.Key.AsString ());
                    mStream.Write (b.Length);
                    mStream.Write (b);
                }
				else if (entry.Key.IsInt ()) {
                   mStream.Write ((int)4);
                    mStream.Write (entry.Key.AsInt ());
                }
				else if (entry.Key.IsLong ()) {
                   mStream.Write ((int)8);
                    mStream.Write (entry.Key.AsLong ());
                }
                else if (entry.Key.IsBoolean ()) {
                    // boolean should not be here
                    return false;
                }
                else {
                    int obj_begin = mStream.Position;
                    int obj_size = 0;
                    mStream.Write (obj_size);

                    if (EncodeInternal(entry.Value.Type, entry.Key, mStream) == false)
                    {
						return false;
					}

                    int obj_end = mStream.Position;
                    obj_size = (int)(obj_end - obj_begin - 4);
                    mStream.Position = obj_begin;
                    mStream.Write (obj_size);
                    mStream.Position = obj_end;
                }
            }
        }

        int end = mStream.Position;
        mStream.Position = begin;
        mStream.Write (fn);
        mStream.Position = end;

        return true;
    }

    public SpObject Decode(string proto, SpStream stream)
    {
        return Decode(mTypeManager.GetType(proto), stream);
    }

    public SpObject Decode(SpType type, SpStream mStream)
    {
        if (mStream == null || type == null)
            return null;

        // buildin type decoding should not be here
        if (mTypeManager.IsBuildinType (type))
            return null;

        SpObject obj = new SpObject ();

        List<int> tags = new List<int> ();
        int current_tag = 0;

        short fn = mStream.ReadInt16 ();
        for (short i = 0; i < fn; i++) {
            int value = (int)mStream.ReadUInt16 ();

            if (value == 0) {
                tags.Add (current_tag);
                current_tag++;
            }
            else {
                if (value % 2 == 0) {
                    SpField f = type.GetFieldByTag (current_tag);
                    if (f == null)
                        continue;

                    value = value / 2 - 1;
                    if (f.Type == mTypeManager.Integer) {
                        obj.Insert (f.Name, value);
                    }
                    else if (f.Type == mTypeManager.Boolean) {
                        obj.Insert (f.Name, (value == 0 ? false : true));
                    }
                    else {
                        continue;
                    }
                    current_tag++;
                }
                else {
                    //System.Console.WriteLine(string.Format("decode value: {0}",value));
                    current_tag += (value + 1) / 2;
                }
            }
        }

		for (int c = 0; c < tags.Count; c++) {
			int tag = tags[c];

            SpField f = type.GetFieldByTag (tag);
            if (f == null)
                continue;

            if (f.IsTable) {
                int size = mStream.ReadInt32 ();
                if (size == 0) continue; //empty table
                if (f.Type == mTypeManager.Integer) {
                    byte n = mStream.ReadByte ();
                    int count = (size - 1) / n;

                    SpObject tbl = new SpObject ();
                    for (int i = 0; i < count; i++) {
                        switch (n) {
                        case 4:
							tbl.Insert (i, mStream.ReadInt32 ());
                            break;
                        case 8:
							tbl.Insert (i, mStream.ReadInt64 ());
                            break;
                        default:
                            return null;
                        }
                    }
					obj.Insert (f.Name, tbl);
                }
                else if (f.Type == mTypeManager.Boolean) {
                    SpObject tbl = new SpObject ();
                    for (int i = 0; i < size; i++) {
						tbl.Insert (i, mStream.ReadBoolean ());
                    }
					obj.Insert (f.Name, tbl);
                }
                else if (f.Type == mTypeManager.String) {
					SpObject tbl = new SpObject ();
					int k = 0;
                    while (size > 0) {
                        int str_len = mStream.ReadInt32 ();
                        size -= 4;
						tbl.Insert (k, Encoding.UTF8.GetString (mStream.ReadBytes (str_len), 0, str_len));
						k++;
                        size -= str_len;
                    }
					obj.Insert (f.Name, tbl);
                }
                else if (f.Type == null) {
                    // unknown type
                    mStream.ReadBytes (size);
                }
                else {
					SpObject tbl = new SpObject ();
					int k = 0;
                    while (size > 0) {
                        int obj_len = mStream.ReadInt32 ();
                        size -= 4;

                        SpObject o = Decode(f.Type, mStream);
						if (f.KeyName != null) {
							tbl.Insert (o.AsTable ()[f.KeyName].Value, o);
						}
                        else
                        {
							tbl.Insert (k, o);
						}
						k++;
                        size -= obj_len;
                    }
					obj.Insert (f.Name, tbl);
                }
            }
            else {
                int size = mStream.ReadInt32 ();

                if (f.Type == mTypeManager.Integer) {
                    switch (size) {
                    case 4:
                        obj.Insert (f.Name, mStream.ReadInt32 ());
                        break;
                    case 8:
                        obj.Insert (f.Name, mStream.ReadInt64 ());
                        break;
                    default:
                        continue;
                    }
                }
                else if (f.Type == mTypeManager.Boolean) {
                    // boolean should not be here
                    return null;
                }
                else if (f.Type == mTypeManager.String) {
                    obj.Insert (f.Name, Encoding.UTF8.GetString (mStream.ReadBytes (size), 0, size));
                }
                else if (f.Type == null) {
                    // unknown type
                    mStream.ReadBytes (size);
                }
                else {
                    obj.Insert(f.Name, Decode(f.Type, mStream));
                }
            }
        }

        return obj;
    }

	private bool IsTypeMatch (SpField f, SpObject o) {
        if (f == null || f.Type == null || o == null)
            return false;

		if (f.IsTable && o.IsTable ()) {
			return true;
		}
		else if (f.Type == mTypeManager.String) {
            if (o.IsString ())
                return true;
        }
        else if (f.Type == mTypeManager.Boolean) {
            if (o.IsBoolean ())
                return true;
        }
        else if (f.Type == mTypeManager.Integer) {
            if (o.IsInt () || o.IsLong ())
                return true;
        }
		else if (o.IsTable ()) {
			return true;
		}

        return false;
    }
}

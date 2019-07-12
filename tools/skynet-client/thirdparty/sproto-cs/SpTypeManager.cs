using System.Collections.Generic;
using System.IO;

public class SpTypeManager : SpProtoParserListener
{
    public readonly SpType Integer = new SpType("integer");
    public readonly SpType String = new SpType("string");
    public readonly SpType Boolean = new SpType("boolean");
    //
    private Dictionary<string, SpProtocol> mProtocols = new Dictionary<string, SpProtocol> ();
    private Dictionary<int, SpProtocol> mProtocolsByTag = new Dictionary<int, SpProtocol> ();

	private Dictionary<string, SpType> mTypes = new Dictionary<string, SpType> ();
	private Dictionary<string, SpType> mIncompleteTypes = new Dictionary<string, SpType> ();
	
    private SpCodec mCodec;

	public SpTypeManager () {
		
        OnNewType(Integer);
        OnNewType(String);
        OnNewType(Boolean);

        mCodec = new SpCodec (this);
	}

	public void OnNewType (SpType type) {
		if (GetType (type.Name) != null)
			return;

		if (IsTypeComplete (type))
			mTypes.Add (type.Name, type);
		else
			mIncompleteTypes.Add (type.Name, type);
	}

	public void OnNewProtocol (SpProtocol protocol) {
		if (GetProtocolByName (protocol.Name) != null || GetProtocolByTag (protocol.Tag) != null)
			return;

        mProtocols.Add (protocol.Name, protocol);
        mProtocolsByTag.Add (protocol.Tag, protocol);
    }

	private bool IsTypeComplete (SpType type) {
		return type.CheckAndUpdate ();
	}

    public SpProtocol GetProtocolByName (string name) {
        if (mProtocols.ContainsKey (name)) {
            return mProtocols[name];
        }
        return null;
    }

    public SpProtocol GetProtocolByTag (int tag) {
        if (mProtocolsByTag.ContainsKey (tag)) {
            return mProtocolsByTag[tag];
        }
        return null;
    }

	public SpType GetType (string name) {
		if (mTypes.ContainsKey (name)) {
			return mTypes[name];
		}

		if (mIncompleteTypes.ContainsKey (name)) {
			SpType t = mIncompleteTypes[name];
			if (IsTypeComplete (t)) {
				mIncompleteTypes.Remove (name);
				mTypes.Add (name, t);
			}
			return t;
		}

		return null;
	}

	public SpType GetTypeNoCheck (string name) {
		if (mTypes.ContainsKey (name)) {
			return mTypes[name];
		}

		if (mIncompleteTypes.ContainsKey (name)) {
			return mIncompleteTypes[name];
		}

		return null;
	}

    public bool IsBuildinType (SpType type) {
        if (type == Integer || type == Boolean || type == String)
            return true;
        return false;
    }
    public bool IsBuildinType(string type)
    {
        if (type == Integer.Name || type == Boolean.Name || type == String.Name)
            return true;
        return false;
    }
    public SpCodec Codec { get { return mCodec; } }

    public static SpTypeManager Import (Stream stream) {
        SpTypeManager instance = new SpTypeManager ();
        new SpProtoParser (instance).Parse (stream);
        return instance;
	}

    public static SpTypeManager Import (string proto) {
        SpTypeManager instance = new SpTypeManager ();
        new SpProtoParser (instance).Parse (proto);
        return instance;
	}
}

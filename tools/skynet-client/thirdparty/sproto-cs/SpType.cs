using System.Collections.Generic;
using System.Text.RegularExpressions;

public class SpType {
	public string Name;
	public Dictionary<int, SpField> Fields = new Dictionary<int, SpField> ();
	public Dictionary<string, SpField> FieldNames = new Dictionary<string, SpField> ();
    public Dictionary<string, SpType> SubSpType = new Dictionary<string, SpType>();
	public SpType (string name) {
		Name = name;
	}

	public void AddField (SpField f) {
		Fields.Add(f.Tag, f);
		FieldNames.Add(f.Name, f);
	}
    public void AddType(SpType f)
    {
        string[] keys = f.Name.Split('.');
        if (keys.Length == 0) return;
        SubSpType.Add(keys[keys.Length-1], f);
    }
    public SpType GetTypeByName(string name)
    {
        if (SubSpType.ContainsKey(name))
            return SubSpType[name];
        return null;
    }
	public SpField GetFieldByName (string name) {
		if (FieldNames.ContainsKey(name))
			return FieldNames[name];
		return null;
	}
	
	public SpField GetFieldByTag (int tag) {
		if (Fields.ContainsKey(tag))
			return Fields[tag];
		return null;
	}

	public bool CheckAndUpdate () {
		bool complete = true;
		foreach (SpField f in Fields.Values) {
			if (f.CheckAndUpdate ())
				continue;
			complete = false; 
		}
		return complete;
	}
}

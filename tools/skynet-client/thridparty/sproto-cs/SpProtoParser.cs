using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;

public interface SpProtoParserListener
{
    void OnNewType(SpType type);
    void OnNewProtocol(SpProtocol protocol);
}

public class SpProtoParser
{
    private SpTypeManager mTypeManager;
    private static char[] sDelimiters = new char[] { '{', '}', '\n' };
    private static char[] sSpace = new char[] { ' ', '\t', '\n' };

    private SpProtocol mCurrentProtocol;
    private SpType mCurrentType;
    private List<SpType> mTypes;
    private string str;

    public SpProtoParser(SpTypeManager m)
    {
        mTypeManager = m;
        mTypes = new List<SpType>();
    }
    public void Parse(Stream stream)
    {
        Parse(ReadAll(stream));
    }
    public void Parse(string str)
    {
        this.str = str;
        mCurrentProtocol = null;
        mCurrentType = null;
        PreProcess();
        Scan(); 
    }

    private string ReadAll(Stream stream)
    {
        string str = "";

        byte[] buf = new byte[1024];
        int len = stream.Read(buf, 0, buf.Length);
        while (len > 0)
        {
            str += Encoding.UTF8.GetString(buf, 0, len);
            len = stream.Read(buf, 0, buf.Length);
        }

        return str;
    }

    private void PreProcess()
    {
        // TODO : trim comment,support comment by #
        str = Regex.Replace(str, @"#[^\r\n]+|\r|\t", string.Empty).Trim();
        str = Regex.Replace(str, @"\s*:\s*", ":");
        str = Regex.Replace(str, @" {2,}", " ");
    }
    
    private void Scan()
    {
        int start = 0;
        while (true)
        {
            int pos = str.IndexOfAny(sDelimiters, start);
            if (pos < 0)
                break;

            switch (str[pos])
            {
                case '{':
                    string title = str.Substring(start, pos - start).Trim();
                    if (IsProtocol(title))
                    {
                        mCurrentProtocol = NewProtocol(title);
                        mTypes.Clear();
                    }
                    else
                    {
                        if (mCurrentType != null)
                        {
                            mTypes.Add(mCurrentType);
                        }
                        mCurrentType = NewType(title);
                        if (mTypes.Count > 0)
                        {
                            mTypes[mTypes.Count - 1].AddType(mCurrentType);
                        }
                    }
                    break;
                case '}':
                    if (mCurrentType != null)
                    {
                        mTypeManager.OnNewType(mCurrentType);
                        if (mCurrentProtocol != null)
                        {
                            mCurrentProtocol.AddType(mCurrentType);
                        }
                        if (mTypes.Count > 0)
                        {
                            mCurrentType = mTypes[mTypes.Count - 1];
                            mTypes.RemoveAt(mTypes.Count - 1);
                        }
                        else
                        {
                            mCurrentType = null;
                        }
                    }
                    else if (mCurrentProtocol != null)
                    {
                        mTypeManager.OnNewProtocol(mCurrentProtocol);
                        mCurrentProtocol = null;
                    }
                    break;
                case '\n':
                    SpField f = NewField(str.Substring(start, pos - start));
                    if (f != null && mCurrentType != null)
                    {
                        mCurrentType.AddField(f);
                    }
                    break;
            }
            start = pos + 1;
        }
    }

    private bool IsProtocol(string str)
    {
        return (str.IndexOfAny(sSpace) >= 0);
    }

    private SpProtocol NewProtocol(string str)
    {
        string[] words = str.Split(sSpace);
        if (words.Length != 2)
            return null;

        SpProtocol protocol = new SpProtocol(words[0], int.Parse(words[1]));
        return protocol;
    }

    private SpType NewType(string str)
    {
        if (str[0] == '.')
        {
            str = str.Substring(1);
            if (mTypes.Count > 0)
                str = mTypes[mTypes.Count - 1].Name + "." + str;
        }
        else
        {
            if (mCurrentProtocol != null)
                str = mCurrentProtocol.Name + "." + str;
        }

        SpType t = new SpType(str);
        return t;
    }

    private SpField NewField(string str)
    {
        if (!str.Contains(":"))
        {
            return null;
        }
        str = str.Replace(":", " ").Trim();
        string[] words = str.Split(' ');

        if (words.Length != 3)
            return null;

        string name = words[0];
        short tag = short.Parse(words[1]);
        string type = words[2];

        bool table = false;
        string key = null;
        if (type[0] == '*')
        {
            table = true;
            type = type.Substring(1);

            int b = type.IndexOf('(');
            if (b > 0)
            {
                int e = type.IndexOf(')');
                key = type.Substring(b + 1, e - b - 1);
                type = type.Substring(0, b);
            }
        }
        if (!mTypeManager.IsBuildinType(type) && mCurrentType != null && mCurrentType.GetTypeByName(type) != null)
        {
            type = string.Format("{0}.{1}", mCurrentType.Name, type);
        }
        SpField f = new SpField(name, tag, type, table, key, mTypeManager);
        return f;
    }
}

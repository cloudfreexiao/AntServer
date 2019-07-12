警告：代码仅供参考，使用前请三思，作者很懒，有issue也不会很快修复的。

sproto-cs
============

# Introduction
sproto-cs is a [sproto](https://github.com/cloudwu/sproto) library writen in c#.

# class

### SpTypeManager
use SpTypeManager to manage your protocols and types.
there's two way to create a SpTypeManager, from stream or from string.

```c#
using (FileStream stream = new FileStream ("foobar.sproto", FileMode.Open)) {
  SpTypeManager tm = SpTypeManager.Import (stream);
}
```
or
```c#
string client_proto = @"
        .package {
	        type 0 : integer
	        session 1 : integer
        }
        ";
SpTypeManager tm = SpTypeManager.Import (client_proto);
```

### SpObject
use SpObject to set/get all data you need.
SpObject could be so many things (int, bool, string, array, table...).

```c#
SpObject a = new SpObject (true);
SpObject b = new SpObject (1000);
SpObject c = new SpObject ("hello");

SpObject obj = new SpObject (SpObject.ArgType.Table, 
    "a", "hello",
    "b", 1000000,
    "c", true,
    "d", new SpObject (SpObject.ArgType.Table,
            "a", "world",
            "c", -1),
    "e", new SpObject (SpObject.ArgType.Array, "ABC", "def"),
    "f", new SpObject (SpObject.ArgType.Array, -3, -2, -1, 0, 1, 2),
    "g", new SpObject (SpObject.ArgType.Array, true, false, true),
    "h", new SpObject (SpObject.ArgType.Array,
            new SpObject (SpObject.ArgType.Table, "b", 100),
            new SpObject (),
            new SpObject (SpObject.ArgType.Table, "b", -100, "c", false),
            new SpObject (SpObject.ArgType.Table, "b", 0, "e", new SpObject (SpObject.ArgType.Array, "test")))
		);

Util.Assert (obj["a"].AsString ().Equals ("hello"));
Util.Assert (obj["b"].AsInt () == 1000000);
Util.Assert (obj["c"].AsBoolean () == true);
Util.Assert (obj["d"]["a"].AsString ().Equals ("world"));
Util.Assert (obj["d"]["c"].AsInt () == -1);
Util.Assert (obj["e"][0].AsString ().Equals ("ABC"));
Util.Assert (obj["e"][1].AsString ().Equals ("def"));
Util.Assert (obj["f"][0].AsInt () == -3);
Util.Assert (obj["f"][1].AsInt () == -2);
Util.Assert (obj["f"][2].AsInt () == -1);
Util.Assert (obj["f"][3].AsInt () == 0);
Util.Assert (obj["f"][4].AsInt () == 1);
Util.Assert (obj["f"][5].AsInt () == 2);
Util.Assert (obj["g"][0].AsBoolean () == true);
Util.Assert (obj["g"][1].AsBoolean () == false);
Util.Assert (obj["g"][2].AsBoolean () == true);
Util.Assert (obj["h"][0]["b"].AsInt () == 100);
Util.Assert (obj["h"][1].Value == null);
Util.Assert (obj["h"][2]["b"].AsInt () == -100);
Util.Assert (obj["h"][2]["c"].AsBoolean () == false);
Util.Assert (obj["h"][3]["b"].AsInt () == 0);
Util.Assert (obj["h"][3]["e"][0].AsString ().Equals ("test"));
```

### SpCodec
use SpCodec to encode/decode your data

```c#
SpStream encode_stream = tm.Codec.Encode ("foobar", obj)
SpObject newObj = tm.Codec.Decode ("foobar", encode_stream);
```

### SpPacker
use SpPacker to pack/unpack your data

```c#
SpStream pack_stream = SpPacker.Pack (encode_stream);
SpStream decode_stream = SpPacker.Unpack (pack_stream);
```

### SpRpc

```c#
SpRpc client = SpRpc.Create (client_proto, "package");
client.Attach (server_proto);
client.Request ("foobar", args, session);
```

# examples
```c#
public void Run () {
  SpTypeManager manager;
  using (FileStream stream = new FileStream (path, FileMode.Open)) {
    manager = SpTypeManager.Import (stream);
  }

  SpObject obj = CreateObject ();

  // encode
  SpStream encode_stream = new SpStream ();
  manager.Codec.Encode ("AddressBook", obj, encode_stream);
  
  // another way to encode obj
  SpStream another_encode_stream = manager.Codec.Encode ("AddressBook", obj);

  // decode
  encode_stream.Position = 0;
  SpObject newObj = manager.Codec.Encode ("AddressBook", encode_stream);

  // pack
  encode_stream.Position = 0;
  SpStream pack_stream = new SpStream ();
  SpPacker.Pack (encode_stream, pack_stream);
  
  // another way to pack
  encode_stream.Position = 0;
  SpStream another_pack_stream = SpPacker.Pack (encode_stream);
  
  // unpack
  pack_stream.Position = 0;
  SpStream unpack_stream = new SpStream ();
  SpPacker.Unpack (pack_stream, unpack_stream);
  
  // another way to pack
  pack_stream.Position = 0;
  SpStream another_unpack_stream = SpPacker.Unpack (pack_stream);

  unpack_stream.Position = 0;
  newObj = manager.Codec.Decode ("AddressBook", unpack_stream);
}

private SpObject CreateObject () {
  SpObject obj = new SpObject ();
  
  SpObject person = new SpObject ();

    SpObject p = new SpObject ();
    p.Insert ("name", "Alice");
    p.Insert ("id", 10000);

    SpObject phone = new SpObject ();
    {
      SpObject p1 = new SpObject ();
      p1.Insert ("number", "123456789");
      p1.Insert ("type", 1);
      phone.Append (p1);
    }

    p.Insert ("phone", phone);
  person.Append (p);

  obj.Insert ("person", person);
  return obj;
}
```

# with unity3d
please check out [sproto-u3d](https://github.com/jintiao/sproto-u3d)


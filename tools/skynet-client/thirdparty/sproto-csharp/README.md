mysproto
========

A pure C# implementation of [sproto](https://github.com/cloudwu/sproto).

## Introduction
Sproto is an efficient serialization library. It's like Google protocol buffers.
The design is simple. It only supports a few types,such as integer/string/boolean/binary/group-buildin-type.

## Usage
```c#
//see Test/SimpleExample.cs
using System;
using System.Collections.Generic;
using Sproto;

namespace TestSproto {
	public static class SimpleExample {
		public static void Run () {
			string c2s =
@"
.package {
	type 0 : integer
	session 1 : integer
}

.Person {
	id 0 : integer			# int type
	name 1 : string			# string type
	age 2 : integer			# int type
	isman 3 : boolean		# bool type
	emails 4 : *string		# string list
	children 5 : *Person	# Person list
	luckydays 6 : *integer  # integer list
}


get 1 {
	request {
		id 0 : integer
	}
	response Person
}
";
			string s2c =
@"
.package {
	type 0 : integer
	session 1 : integer
}
";
			SprotoMgr S2C = SprotoParser.Parse(s2c);
			SprotoMgr C2S = SprotoParser.Parse(c2s);
			SprotoRpc Client = new SprotoRpc(S2C,C2S);
			SprotoRpc Server = new SprotoRpc(C2S,S2C);
			// create a request
			SprotoObject request = Client.C2S.NewSprotoObject("get.request");
			request["id"] = 1;
			RpcPackage request_package = Client.PackRequest("get",request,1);

			RpcMessage message = Server.UnpackMessage(request_package.data,request_package.size);
			// create a response
			//SprotoObject response = Client.C2S.NewSprotoObject("Person");
			SprotoObject response = Server.S2C.NewSprotoObject("Person");
			response["id"] = 1;
			response["name"] = "sundream";
			response["age"] = 26;
			response["emails"] = new List<string>{
				"linguanglianglgl@gmail.com",
			};
			//List<SprotoObject> children = new List<SprotoObject>();
			// no children
			//response["children"] = children;
			response["luckydays"] = new List<Int64>{0,6};
			RpcPackage response_package = Server.PackResponse("get",response,1);
			message = Client.UnpackMessage(response_package.data,response_package.size);
			Console.WriteLine("proto={0},tag={1},ud={2},session={3},type={4},request={5},response={6}",
					message.proto,message.tag,message.ud,message.session,message.type,message.request,message.response);

		}
	}
}
```

## C# API
* `SprotoMgr SprotoParser.Parse(string proto,string filename="=text")` create a sprotomgr by proto string(encoding in utf-8)
* `SprotoMgr SprotoParser.ParseFile(string filename)` create a sprotomgr by proto file(encoding in utf-8)
* `SprotoMgr SprotoParser.ParseFromBinary(byte[] bytes,int length)` create a sprotomgr from binary proto
* `SprotoMgr SprotoParser.ParseFromBinaryFile(string filename)` create a sprotomgr from binary proto file
* `byte[] SprotoParser.DumpToBinary(SprotoMgr sprotomgr)` dump a sprotomgr to binary proto
* `SprotoObject SprotoMgr.NewSprotoObject(string typename,object val=null)` create a SprotoObject by typename,we can set field like dict later
* `SprotoStream SprotoMgr.Encode(SprotoObject obj,SprotoStream writer=null)` encode a SprotoObject
* `SprotoObject SprotoMgr.Decode(string typename,SprotoStream reader)` decode to a SprotoObject
* `byte[] SprotoMgr.Pack(byte[] src,int start,int length,out int size,byte[] dest=null)` 0-pack a byte-buffer
* `byte[] SprotoMgr.Unpack(byte[] src,int start,int length,out int size,byte[] dest=null)` 0-unpack a byte-buffer
* `SprotoRpc SprotoRpc(SprotoMgr S2C,SprotoMgr C2S,string package="package")` create a SprotoRpc by a S2C sprotomgr and a C2S sprotomgr
* `RpcPackage SprotoRpc.Request(string proto,SprotoObject request=null,Int64 session=0)` create a request package
* `RpcPackage SprotoRpc.Response(string proto,SprotoObject response=null,Int64 session=0)` create a response package
* `RpcPackage SprotoRpc.PackMessage(RpcMessage message)` pack request/response message to package
* `RpcMessage SprotoRpc.UnPackMessage(byte[] bytes,int size)` unpack to a message,may request/response

## Benchmark
In my i5-3210 @2.5GHz CPU, the benchmark is below:

|library         | encode 1M times | decode 1M times | size
|----------------| --------------- | --------------- | ----
|sproto(nopack)  | 9.193s          | 9.963s          | 130 bytes
|sproto          | 10.000s         | 10.411s         | 83 bytes

## Run
```
i test in ubuntu/mac
1. compile: mcs *.cs Test/*.cs
2. run: ls *.exe | xargs mono
```
* if you want to use in unity,see [TcpClientSocket](https://github.com/sundream/TcpClientSocket)

## See Also
* [sproto](https://github.com/cloudwu/sproto)
* [sproto-cs](https://github.com/jintiao/sproto-cs)
* [sproto-Csharp](https://github.com/lvzixun/sproto-Csharp)
* [sprotoparser](https://github.com/spin6lock/yapsp)

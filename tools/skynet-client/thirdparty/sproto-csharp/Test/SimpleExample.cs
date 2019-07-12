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

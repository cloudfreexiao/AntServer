using System;
using Sproto;

namespace TestSproto {
	public static class TestSprotoRpc {
		public static void Run () {
			Console.WriteLine("TestSprotoRpc.Run ...");
			string c2s =
@".package {
	type 0 : integer
	session 1 : integer
}

foobar 1 {
	request {
		what 0 : string
	}
	response {
		ok 0 : boolean
	}
}

foo 2 {
	response {
		ok 0 : boolean
	}
}

bar 3 {
	response nil
}

blackhole 4 {
}
";

			string s2c =
@".package {
	type 0 : integer
	session 1 : integer
}
";
			SprotoMgr S2C = SprotoParser.Parse(s2c);
			SprotoMgr C2S = SprotoParser.Parse(c2s);
			SprotoRpc Client = new SprotoRpc(S2C,C2S);
			SprotoRpc Server = new SprotoRpc(C2S,S2C);
			// test proto foobar
			SprotoObject request = Client.C2S.NewSprotoObject("foobar.request");
			request["what"] = "foo";
			RpcPackage request_package = Client.PackRequest("foobar",request,1);
			Console.WriteLine("Client request foobar: data={0},size={1}",request_package.data,request_package.size);
			RpcMessage message = Server.UnpackMessage(request_package.data,request_package.size);

			SprotoHelper.Assert(message.proto == "foobar");
			SprotoHelper.Assert(message.type == "request","not a request");
			SprotoHelper.Assert(message.request != null);
			SprotoHelper.Assert(message.request["what"] == "foo");
			SprotoHelper.Assert(message.session == 1);
			SprotoObject response = Client.C2S.NewSprotoObject("foobar.response");
			response["ok"] = true;
			RpcPackage response_package = Server.PackResponse(message.proto,response,message.session);
			Console.WriteLine("Server resonse foobar: data={0},size={1}",response_package.data,response_package.size);
			message = Client.UnpackMessage(response_package.data,response_package.size);
			SprotoHelper.Assert(message.proto == "foobar");
			SprotoHelper.Assert(message.type == "response","not a response");
			SprotoHelper.Assert(message.response != null);
			SprotoHelper.Assert(message.response["ok"] == true);
			SprotoHelper.Assert(message.session == 1);

			// test proto foo
			request_package = Client.PackRequest("foo",null,2);
			Console.WriteLine("Client request foo: data={0},size={1}",request_package.data,request_package.size);
			message = Server.UnpackMessage(request_package.data,request_package.size);

			SprotoHelper.Assert(message.proto == "foo");
			SprotoHelper.Assert(message.type == "request","not a request");
			SprotoHelper.Assert(message.request == null); // no request data
			SprotoHelper.Assert(message.session == 2);
			response = Client.C2S.NewSprotoObject("foo.response");
			response["ok"] = false;
			response_package = Server.PackResponse(message.proto,response,message.session);
			Console.WriteLine("Server resonse foo: data={0},size={1}",response_package.data,response_package.size);
			message = Client.UnpackMessage(response_package.data,response_package.size);
			SprotoHelper.Assert(message.proto == "foo");
			SprotoHelper.Assert(message.type == "response","not a response");
			SprotoHelper.Assert(message.response != null);
			SprotoHelper.Assert(message.response["ok"] == false);
			SprotoHelper.Assert(message.session == 2);

			// test proto bar
			request_package = Client.PackRequest("bar",null,3);
			Console.WriteLine("Client request bar: data={0},size={1}",request_package.data,request_package.size);
			message = Server.UnpackMessage(request_package.data,request_package.size);

			SprotoHelper.Assert(message.proto == "bar");
			SprotoHelper.Assert(message.type == "request","not a request");
			SprotoHelper.Assert(message.request == null); // no request data
			SprotoHelper.Assert(message.session == 3);
			response_package = Server.PackResponse(message.proto,null,message.session);
			Console.WriteLine("Server resonse bar: data={0},size={1}",response_package.data,response_package.size);
			message = Client.UnpackMessage(response_package.data,response_package.size);
			SprotoHelper.Assert(message.proto == "bar");
			SprotoHelper.Assert(message.type == "response","not a response");
			SprotoHelper.Assert(message.response == null); // no response data
			SprotoHelper.Assert(message.session == 3);
		
			// test proto blackhole
			request_package = Client.PackRequest("blackhole",null,0);
			Console.WriteLine("Client request blackhole: data={0},size={1}",request_package.data,request_package.size);
			message = Server.UnpackMessage(request_package.data,request_package.size);

			SprotoHelper.Assert(message.proto == "blackhole");
			SprotoHelper.Assert(message.type == "request","not a request");
			SprotoHelper.Assert(message.request == null); // no request data
			SprotoHelper.Assert(message.session == 0);
			// session == 0 mean: can donn't response

			Client.C2S.Dump();
			Console.WriteLine("TestSprotoRpc.Run ok");
		}
	}
}


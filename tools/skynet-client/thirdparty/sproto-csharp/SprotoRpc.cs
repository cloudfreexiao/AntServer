using System;
using System.Collections.Generic;

namespace Sproto {
	public class RpcPackage {
		public byte[] data = null;
		public int size = 0;
	}

	public class RpcMessage {
		public Int64 session = 0;
		public SprotoObject ud = null; //userdata in header,such as message_id
		public string proto = null;	// proto name
		public UInt16 tag = 0;		// proto tag
		public SprotoObject request = null;
		public SprotoObject response = null;
		public string type = null; //request or response
	}

	public class SprotoRpc {
		public SprotoMgr S2C; // endpoint -> me
		public SprotoMgr C2S; // me -> endpoint
		private SprotoStream writer;
		private SprotoStream reader;
		private Dictionary<Int64,RpcMessage> sessions;
		private string package;

		public SprotoRpc (SprotoMgr S2C,SprotoMgr C2S,string package="package") {
			this.S2C = S2C;
			this.C2S = C2S;
			this.sessions = new Dictionary<Int64,RpcMessage>();
			this.package = package;
			this.writer = new SprotoStream();
			this.reader = new SprotoStream();
		}

		public RpcPackage PackMessage(RpcMessage message) {
			if (message.type == "request") {
				return this.PackRequest(message.proto,message.request,message.session,message.ud);
			} else {
				SprotoHelper.Assert(message.type == "response",String.Format("invalid message type: {0}",message.type));
				return this.PackResponse(message.proto,message.response,message.session,message.ud);
			}
		}

		public RpcPackage PackRequest(string proto,SprotoObject request=null,Int64 session=0,SprotoObject ud=null) {
			//Console.WriteLine("PackRequest {0} {1} {2}",proto,request,session);
			SprotoProtocol protocol = this.C2S.GetProtocol(proto);
			UInt16 tag = protocol.tag;
			SprotoObject header = this.NewPackageHeader(this.C2S,tag,session,ud);
			this.writer.Seek(0,SprotoStream.SEEK_BEGIN); // clear stream
			SprotoStream writer = this.C2S.Encode(header,this.writer);
			if (request != null) {
				string expect = protocol.request;
				if (request.type != expect)
					SprotoHelper.Error("[SprotoRpc.Request] expect '{0}' got '{1}'",expect,request.type);
				writer = this.C2S.Encode(request,writer);
			}
			RpcPackage package = new RpcPackage();
			package.data = this.C2S.Pack(writer.Buffer,0,writer.Position,out package.size);
			if (session != 0) {
				SprotoHelper.Assert(!this.sessions.ContainsKey(session),String.Format("repeat session: {0}",session));
				RpcMessage message = new RpcMessage();
				message.session = session;
				message.proto = proto;
				message.request = request;
				message.tag = tag;
				this.sessions[session] = message;
			}
			return package;
		}

		public RpcPackage PackResponse(string proto,SprotoObject response=null,Int64 session=0,SprotoObject ud=null) {
			//Console.WriteLine("PackResponse {0} {1} {2}",proto,response,session);
			SprotoProtocol protocol = this.S2C.GetProtocol(proto);
			SprotoObject header = this.NewPackageHeader(this.S2C,0,session,ud);
			this.writer.Seek(0,SprotoStream.SEEK_BEGIN); // clear stream
			SprotoStream writer = this.S2C.Encode(header,this.writer);
			if (response != null) {
				string expect = protocol.response;
				if (response.type != expect)
					SprotoHelper.Error("[SprotoRpc.Response] expect '{0}' got '{1}'",expect,response.type);
				writer = this.S2C.Encode(response,writer);
			}
			RpcPackage package = new RpcPackage();
			package.data = this.S2C.Pack(writer.Buffer,0,writer.Position,out package.size);
			return package;
		}

		public RpcMessage UnpackMessage(byte[] bytes,int size) {
			RpcMessage message = null;
			int bin_size = 0;
			byte[] bin = this.S2C.Unpack(bytes,0,size,out bin_size);
			this.reader.Seek(0,SprotoStream.SEEK_BEGIN); // clear stream
			this.reader.Buffer = bin;

			SprotoObject header = this.S2C.Decode(this.package,this.reader);
			if (header["type"] != null) {
				// request
				UInt16 tag = (UInt16)header["type"];
				SprotoProtocol protocol = this.S2C.GetProtocol(tag);
				SprotoObject request = null;
				if (protocol.request != null) {
					request = this.S2C.Decode(protocol.request,this.reader);
				}

				message = new RpcMessage();
				message.type = "request";
				if (header["session"] != null)
					message.session = header["session"];
				if (header["ud"] != null)
					message.ud = header["ud"];
				message.proto = protocol.name;
				message.tag = protocol.tag;

				message.request = request;
			} else {
				// response
				SprotoHelper.Assert(header["session"] != null,"session not found");
				Int64 session = header["session"];
				if (this.sessions.TryGetValue(session,out message)) {

					//Console.WriteLine("remove session {0}",session);
					this.sessions.Remove(session);

				}
				SprotoHelper.Assert(message != null,"unknow session");
				message.type = "response";
				if (header["ud"] != null)
					message.ud = header["ud"];
				SprotoProtocol protocol = this.C2S.GetProtocol(message.tag);
				if (protocol.response != null) {

					SprotoObject response = this.C2S.Decode(protocol.response,this.reader);
					message.response = response;
				}
			}
			return message;
		}

		private SprotoObject NewPackageHeader(SprotoMgr sprotomgr,UInt16 tag,Int64 session,SprotoObject ud=null) {
			SprotoObject header = sprotomgr.NewSprotoObject(this.package);
			if (tag != 0) { // tag == 0 mean : response header
				header["type"] = tag;
			} else {
				SprotoHelper.Assert(session != 0,"response expect session");
			}
			if (session != 0)
				header["session"] = session;
			if (ud != null)
				header["ud"] = ud;
			return header;
		}
	}
}

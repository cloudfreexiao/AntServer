let s2c = `
.package {
    type 0 : integer
    session 1 : integer
}

.h5 {
    id 0: integer
    name 1: string
}

heartbeat 1 {}

userInfo 2 {
    request {
        name 0: string
        age 1: integer
        hs 2: h5
    }

    response {
        flag 0: boolean
    }
}

`;

let c2s = `
.package {
    type 0 : integer
    session 1 : integer
}

handshake 1 {
    response {
        msg 0  : string
    }
}

get 2 {
    request {
        what 0 : string
    }
    response {
        result 0 : string
    }
}

set 3 {
    request {
        what 0 : string
        value 1 : string
    }
}

quit 4 {}


`;

import { Sproto } from "./sproto";

// 创建客户端sproto实例，服务端sproto实例
// 因为是单个文件测试，所以客户端和服务端 host 共同保存到同一个静态数组中
let csp = new Sproto(c2s);
csp.host(new Sproto(s2c));    // s2c index is 0

let ssp = new Sproto(s2c);
ssp.host(new Sproto(c2s));    // cs2 index is 1



// 测试 client --> server
// -----------client send msg
console.log("--------------test1(client --> server)");
let client_request = csp.attach();
let session = 1;
let req = client_request("get", {what: "hello server"}, session);

// -----------server receive msg
let srecv = ssp.dispatch(req, 1);
console.log(srecv.replay, srecv.result);
let resp = srecv.response({result: "hello client"})

// -----------client receive msg 
let crecv = csp.dispatch(resp, 0)
console.log(crecv.replay, crecv.result);



/*
说明:
为了区分服务端消息是回应的，还是主动推送的可以通过 
replay参数来区分，如果是回应的，那么replay = "RESPONSE"，
如果是推送的，replay = "REQUEST"
 */
// 测试 server --> client(server active push)
console.log("\n--------------test2(server --> client)");
let server_request = ssp.attach();
session = 2;
req = server_request("userInfo", {name: "tom", age: 18, hs: {id: 1010, name: "xxx"}}, session);

// -----------client receive msg 
crecv = csp.dispatch(req, 0)
console.log(crecv.replay, crecv.result);
resp = crecv.response({flag: true});

// -----------server receive msg
srecv = ssp.dispatch(resp, 1);
console.log(srecv.replay, srecv.result);



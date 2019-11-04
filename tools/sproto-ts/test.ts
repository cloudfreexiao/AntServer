let proto = `
.package {
    type 0: integer
    session 1: integer
}

foobar 1 {
    request {
        what 0 : string
        value 1: string
    }
    response {
        ok 0 : boolean
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
`;

import { Sproto } from "./sproto";
let sp = new Sproto(proto);

console.log("======================test1");
let session = 1;
let client_request = sp.attach();
let req = client_request("foobar", { what: "hello", value: "lindx 不喜欢写代码" }, session);
let data = sp.dispatch(req);
//　如果是一个　request 请求， data　包含replay="REQUEST"　以及　result　数据
console.log(data.replay, data.result);

let resp = data.response({ ok: false });
data = sp.dispatch(resp);
// 如果是一个　response 响应，那么　data 包含　replay＝"RESPONSE", session, result
console.log(data.replay, data.session, data.result);

console.log("======================test2");
let packbuffer = sp.pencode("package", {session: 12, type: 0});
let rt = sp.pdecode("package", packbuffer);
console.log(rt);



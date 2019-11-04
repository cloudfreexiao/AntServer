# Sproto Typescript版

#### 项目介绍
Typescript版的sproto，sproto是skynet框架的一个通信模块，ts版的sproto不需要过多的依赖其他工具。像lua那样可以直接引用sproto协议。  

例如：
```ts
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
        what 0 : string   #参数1
        value 1 : string  #参数2
    }
}
`;

let sp = new Sproto(proto); //加载协议内容，初始化
let client_request = sp.attach();    //获取一个request请求的回调函数
let req = client_request("foobar", { what: "hello", value: "lindx 不喜欢写代码" }, session); //req是一个Buffer数据类型，可以直接base64编码后发送给 skynet 服务端。

let data = sp.dispatch(req);    //这个对应于 host:dispatch(req)
console.log(data.result);       //打印数据

```


#### 安装教程

1. 需要到nodejs的buffer模块，所以首先要安装nodejs，网上有安装教程，这里就不介绍
2. 引用buffer模块，执行　npm install -s @types/buffers

#### 其他情况下
如果是在cocos creator环境下或者其他环境下，没能装上nodejs，那么可以使用buffer目录下的buffer.js模块．  

buffer目录下的文件就是直接拿nodejs　Buffer模块的源码．并在　sproto.ts　的第一行加上
```js
import { Buffer } from "buffer";
```


#### 运行
```js
tsc test.ts
node test.js
```

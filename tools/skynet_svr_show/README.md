
#### 用web展示skynet 服务的详情，非侵入式，即不需要在skynet逻辑代码中添加任何代码，只需要打开调试端口
#### 实现原理：给skynet的自身的调试接口发送指令，然后解析数据，参考skynet wiki https://github.com/cloudwu/skynet/wiki/DebugConsole



### web后端：Flask
### web前端：layui

### 使用：
#### 安装及使用Flask，参考这篇http://docs.jinkan.org/docs/flask/

#### 运行程序：
##### export FLASK_APP=svr.py
##### flask run --host=your_ip  (要想在外部也能访问，必须使用机器的ip地址)

### 访问接口：
#### /skynet/port/method
#### port是要访问skynet服务监听的调试端口
#### 目前实现的method有list，mem

#### 示例：http://192.168.1.136:5000/skynet/8001/list

#### TODO: nodejs 替换 python 实现
https://www.digitalocean.com/community/tutorials/how-to-develop-a-node-js-tcp-server-application-using-pm2-and-nginx-on-ubuntu-16-04






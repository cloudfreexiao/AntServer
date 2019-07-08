# random-lua-opcodes

随机 lua 源码中字节码的定义，并编译 lua

* **compile_lua.sh** - 下载指定版本 lua 并编译已随机字节码和未随机字节码的两个版本到临时目录中，并且链接两个版本的 lua / luac 到工作目录，非 mac 平台需要指定一个平台参数用于编译 lua
* **test.lua** - 一段用于测试的 lua 逻辑代码
* **test.sh** - test.sh 用两个版本的 lua 编译 test.lua 到字节码并且各自执行，以及用标准 lua 尝试执行已混淆 opcode 的 lua 字节码
* **rand_opcodes.lua** - 随机排列 lua 源代码中的 lopcodes.h / lopcodes.c 定义

对于需要编译 android / ios / windows 平台的 lua，请自行处理。
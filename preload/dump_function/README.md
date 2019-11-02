# dump_lua_function

Convert lua stack backtrace file from filename:lineno to filename:funcname. Fail on nested function definition.


Usage:
======
```lua
lua dump.lua project_src_dir your_lua_bt_file | tee new_bt_filename
```

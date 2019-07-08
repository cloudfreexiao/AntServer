#!/usr/bin/env sh

echo "========== standard lua =========="
./standard_luac -o test.standard.luac test.lua
./standard_lua test.standard.luac

echo "========== rand opcodes lua =========="
./rand_opcodes_luac -o test.rand.luac test.lua
./rand_opcodes_lua test.rand.luac

echo "========== standard lua load rand opcodes luac file =========="
./standard_lua test.rand.luac


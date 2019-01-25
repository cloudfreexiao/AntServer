-- sample for termfx
-- Gunnar Zötl <gz@tset.de>, 2014-2015
-- Released under the terms of the MIT license. See file LICENSE for details.

--[[
  simpleui.lua

  very simple ui elements for termfx samples:

  ui = require "simpleui"

  ui.box(x, y, w, h)
    draws a box with a frame

  ui.ask(msg)
    prints a message and gives the option to select Yes or No.
    Returns true if Yes was selected, false otherwise

  ui.message(msg)
    prints a message in a box and returns on ESC, Return or Space.

  ui.select(msg, tbl)
    presents a list of up to 9 items with a header, allows to select
    an item by number, or ESC, Return or Space to exit without
    selecting. Returns the selected number, or false if ESC, Return
    or Space was pressed.
--]]
local _M = {}

local tfx = require "termfx"

local function draw_box(x, y, w, h)
  local ccell = tfx.newcell('+')
  local hcell = tfx.newcell('-')
  local vcell = tfx.newcell('|')

  for i = x, x+w do
    tfx.setcell(i, y-1, hcell)
    tfx.setcell(i, y+h, hcell)
  end
  for i = y, y+h do
    tfx.setcell(x-1, i, vcell)
    tfx.setcell(x+w, i, vcell)
  end
  tfx.setcell(x-1, y-1, ccell)
  tfx.setcell(x-1, y+h, ccell)
  tfx.setcell(x+w, y-1, ccell)
  tfx.setcell(x+w, y+h, ccell)

  tfx.rect(x, y, w, h, ' ', fg, bg)
end

_M.box = draw_box

local function frame(w, h)
  local tw, th = tfx.size()
  if w + 2 > tw then w = tw - 2 end
  if h + 2 > th then h = th - 2 end
  local x = math.floor((tw - w) / 2)
  local y = math.floor((th - h) / 2)

  draw_box(x, y, w, h)

  return x, y, w, h
end

function _M.ask(msg)
  local mw = #msg
  if mw < 6 then mw = 6 end
  local x, y, w, h = frame(mw, 3)
  tfx.printat(x, y, msg, w)
  local p = x + math.floor((w - 6) / 2)
  tfx.attributes(tfx.color.BLACK, tfx.color.GREEN)
  tfx.printat(p, y+2, "Yes")
  tfx.attributes(tfx.color.BLACK, tfx.color.RED)
  tfx.printat(p+4, y+2, "No")
  tfx.present()

  local answer = nil
  while answer == nil do
    local evt = tfx.pollevent()
    if evt.char == 'y' or evt.char == 'Y' then
      answer = true
    elseif evt.char == 'n' or evt.char == 'N' then
      answer = false
    end
  end
  return answer
end

function _M.message(msg)
  local mw = #msg
  local x, y, w, h = frame(mw, 3)
  tfx.printat(x, y, msg, w)
  local p = x + math.floor((w - 2) / 2)
  tfx.attributes(tfx.color.BLACK, tfx.color.GREEN)
  tfx.printat(p, y+2, "Ok")
  tfx.present()

  local evt
  repeat
    evt = tfx.pollevent()
  until evt.key == tfx.key.ENTER or evt.key == tfx.key.SPACE or evt.key == tfx.key.ESC
end

function _M.select(msg, tbl)
  local mw = #msg
  local mh = #tbl
  if mh > 9 then mh = 9 end
  for i=1, mh do
    if mw < #tbl[i] + 2 then mw = #tbl[i] + 2 end
  end

  local x, y, w, h = frame(mw, mh+2)
  tfx.printat(x, y, msg, w)
  for i=1, mh do
    tfx.printat(x, y+1+i, i.." "..tbl[i], w)
  end
  tfx.present()

  local answer = nil
  while answer == nil do
    local evt = tfx.pollevent()
    if evt.char >= '1' and evt.char <= tostring(mh) then
      answer = tbl[tonumber(evt.char)]
    elseif evt.key == tfx.key.ENTER or evt.key == tfx.key.SPACE or evt.key == tfx.key.ESC then
      answer = false
    end
  end
  return answer
end

return _M

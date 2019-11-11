local make_component = require("entitas.index").make_component

-- https://blog.codingnow.com/2006/10/aoi.html
-- https://blog.codingnow.com/2012/03/dev_note_13.html

-- https://www.cnblogs.com/Lifehacker/p/skynet_systemtap_for_service.html

-- 基本的 AOI 系统中，对象只有方位坐标是为 AOI 模块所知的。如果希望让每个玩家的视野有所不同，对于观察者（玩家）可能还需要多设定一个视野半径的参数。
-- 如上面举出的盗贼隐身一例，解决那种逻辑这些数据是不够的。

-- 我所构想的系统中，观察者有两个参数，雷达半径和雷达强度；而被观察者除了坐标外，还有一个信号半径的参数。
-- （这里，玩家通常既是观察者又是被观察者；而 npc 是纯粹的被观察者）

-- 雷达半径就是前面所说的视野半径；而雷达强度决定了在离目标一定距离时，可以分辨的最大尺寸的物体。
-- 这个尺寸当然不是指对象的模型大小，而是指被观察者的信号半径。

-- 有了这几组数据，我们就可以决定被观察者是否为观察者所见。
-- 通常，雷达半径、强度，和物体的信号半径都是不变的。但是，游戏逻辑可以根据需要来改变它们；
-- 比如通过装备、升级、战斗时 buffer 等等。
-- 不过底层 engine 不需要了解这些逻辑的细节，只需要把基本参数拿出来算一下就可以确定了。

local M = {
    scene_cell_component = make_component("scene_cell_component", "id", "name", "spriteid"),
    position_component = make_component("position_component", "x", "y"),
    -- direction_component = make_component("Direction", "x", "y"),
    mover_component = make_component("mover_component"),
    speed_component = make_component("speed_component","value"),
    radar_radius_component =  make_component("radar_radius_component", "value"), -- 雷达半径就是视野半径
    radar_signal_component =  make_component("radar_signal_component", "value"), -- 雷达信号强度
    dead_component =  make_component("dead_component"),
}

return M
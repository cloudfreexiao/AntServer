--[[
/**********************************************************\
|                                                          |
|                          hprose                          |
|                                                          |
| Official WebSite: http://www.hprose.com/                 |
|                   http://www.hprose.org/                 |
|                                                          |
\**********************************************************/

/**********************************************************\
 *                                                        *
 * hprose/result_mode.lua                                 *
 *                                                        *
 * hprose result_mode for Lua                             *
 *                                                        *
 * LastModified: Apr 22, 2014                             *
 * Author: Ma Bingyao <andot@hprose.com>                  *
 *                                                        *
\**********************************************************/
--]]

return {
    Normal        = 0,
    Serialized    = 1,
    Raw           = 2,
    RawWithEndTag = 3
}

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
 * hprose/tags.lua                                        *
 *                                                        *
 * hprose Tags for Lua                                    *
 *                                                        *
 * LastModified: Apr 25, 2014                             *
 * Author: Ma Bingyao <andot@hprose.com>                  *
 *                                                        *
\**********************************************************/
--]]

return {
    -- Serialize Tags --
    Integer  = 'i',
    Long     = 'l',
    Double   = 'd',
    Null     = 'n',
    Empty    = 'e',
    True     = 't',
    False    = 'f',
    NaN      = 'N',
    Infinity = 'I',
    Date     = 'D',
    Time     = 'T',
    UTC      = 'Z',
    Bytes    = 'b',
    UTF8Char = 'u',
    String   = 's',
    Guid     = 'g',
    List     = 'a',
    Map      = 'm',
    Class    = 'c',
    Object   = 'o',
    Ref      = 'r',
    -- Serialize Marks --
    Pos        = '+',
    Neg        = '-',
    Semicolon  = ';',
    Openbrace  = '{',
    Closebrace = '}',
    Quote      = '"',
    Point      = '.',
    -- Protocol Tags --
    Functions = 'F',
    Call      = 'C',
    Result    = 'R',
    Argument  = 'A',
    Error     = 'E',
    End       = 'z'
}
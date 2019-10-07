#include <assert.h>
#include <string.h>
#include "lua-recastnavigation.h"
#include "recastnavigator.h"

static int _nav_create(lua_State *L)
{
  const char *pszFile = luaL_checkstring(L,1);
  float walkableHeight = (float)luaL_checknumber(L,2);
  float walkableRadius = (float)luaL_checknumber(L,3);
  float walkableClimb = (float)luaL_checknumber(L,4);
  float fscale = (float)luaL_checknumber(L,5);
  float fstep = (float)luaL_checknumber(L,6);
  float fslop = (float)luaL_checknumber(L,7);
  int maxSearchNode = (float)luaL_optinteger(L,8, 2048);

  CNavigator *nav = new CNavigator();
  bool suc = nav->init( pszFile, walkableHeight, walkableRadius, walkableClimb,
                        fscale, fstep, fslop, maxSearchNode);
  if(suc)
  {
    lua_pushlightuserdata(L, (void *)nav);
  }
  else
  {
    lua_pushnil(L);
  }
  return 1;
}

static CNavigator *check_nav_ptr(lua_State* L, int i)
{
  if(!lua_islightuserdata(L, 1))
    luaL_error(L, "Param1 must user data!");

  CNavigator *nav = (CNavigator *)lua_touserdata(L, 1);
  if(!nav)
    luaL_error(L, "Null point of navigator!");

  return nav;
}

static int _nav_destroy(lua_State *L)
{
  CNavigator* nav = check_nav_ptr(L, 1);
  delete nav;
  nav = 0;

  return 1;
}

static int _nav_query(lua_State *L)
{
  CNavigator* nav = check_nav_ptr(L, 1);

  float spos[3] = {0};
  float epos[3] = {0};
  int steps = 1;

  lua_getfield(L, 2, "x");
  spos[0] = (float)luaL_checknumber(L,1);
  lua_getfield(L, 2, "y");
  spos[0] = (float)luaL_checknumber(L,1);
  lua_getfield(L, 2, "z");
  spos[0] = (float)luaL_checknumber(L,1);

  lua_getfield(L, 3, "x");
  epos[0] = (float)luaL_checknumber(L,1);
  lua_getfield(L, 3, "y");
  epos[0] = (float)luaL_checknumber(L,1);
  lua_getfield(L, 3, "z");
  epos[0] = (float)luaL_checknumber(L,1);


  steps = luaL_optinteger(L, 4, 5);
  assert(steps > 0);

  float *result = (float*)malloc(sizeof(float)*steps);
  if (!result)
  {
    luaL_error(L, "Not enough memory!");
  }
  memset(result, 0, sizeof(float)*steps);
  int nres = 0;
  bool suc = nav->queryPath(spos, epos, steps, result, &nres);
  if(!suc)
  {
    lua_pushboolean(L, false);
  }
  else
  {
    //1 success
    lua_pushboolean(L, suc);

    //2 result
    lua_newtable(L);
    for(int i=0; i<nres; i++)
    {
      float x = result[i*3];
      float y = result[i*3+1];
    //   float z = result[i*3+2];

      lua_newtable(L);
      lua_pushnumber(L, x);
      lua_setfield(L, -2, "x");

      lua_newtable(L);
      lua_pushnumber(L, y);
      lua_setfield(L, -2, "x");

      lua_newtable(L);
      lua_pushnumber(L, y);
      lua_setfield(L, -2, "x");

      lua_settable(L, -2);
    }
  }

  free(result);
  result = 0;

  return 1;
}

static int _nav_exclude(lua_State *L)
{
  CNavigator* nav = check_nav_ptr(L, 1);
  int flag = (int)luaL_optinteger(L, 2, 0);
  nav->setExclude(flag);
  return 1;
}

int luaopen_navigator(lua_State *L)
{
  luaL_checkversion(L);

  luaL_Reg l[] = {
    {"create", _nav_create},
    {"destroy", _nav_destroy},
    {"query", _nav_query},
    {"exclude", _nav_exclude},
    { NULL, NULL },
  };

  luaL_newlib(L,l);
  return 1;
}
// Copyright (c) 2017 liwq, SAE

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "lua.h"
#include "lauxlib.h"

#ifndef LUAEXT_MODNAME
#define LUAEXT_MODNAME   "luaext"
#endif

#ifndef LUAEXT_VERSION
#define LUAEXT_VERSION   "1.0devel"
#endif


// gcc -fPIC -shared luaext.c -o luaext.so -I/usr/local/include/luajit-2.0 -L/usr/local/lib/ -lluajit-5.1
 
static int luaext_error(lua_State *L, const char *info) {
    lua_pushnil(L);

    if (NULL == info) {
        lua_pushstring(L, "unknown error");
    } else {
        lua_pushstring(L, info);
    }

    return 2;
}

static int luaext_bor(lua_State *L) {
    int num;
    int i, n;

    if (lua_isnumber(L, 1)) {
        num = (int)lua_tonumber(L, 1);
    } else {
        return luaext_error(L, "invalid number");
    }

    n = lua_gettop(L);
    for (i=2; i<=n; i++) {
        if (lua_isnumber(L, 1)) {
        num |= (int)lua_tonumber(L, i);
        } else {
            return luaext_error(L, "invalid number");
        }
    }

    lua_pushnumber(L, num);
    return 1;
}


static int luaext_access(lua_State *L) {
    const char *fileName  = NULL;
    char *errMsg          = NULL;
    int flag              = F_OK;

    if (lua_isstring(L, 1)) {
        fileName = lua_tostring(L, 1);
    } else {
        return luaext_error(L, "invalid filename");
    }

    if (lua_isnumber(L, 2)) {
        flag = (int)lua_tonumber(L, 2);
    } else {
        return luaext_error(L, "invalid flag");
    }

    if (access(fileName, flag) == 0) {
        lua_pushboolean(L, 1);
    } else {
        errMsg = (char *) strerror(errno);
        return luaext_error(L, errMsg);
    }

    return 1;
}


static int luaext_mkdir(lua_State *L) {
    const char *path  = NULL;
    char *errMsg      = NULL;
    mode_t mode;

    if (lua_isstring(L, 1)) {
        path = lua_tostring(L, 1);
    } else {
        return luaext_error(L, "invalid path");
    }

    if (lua_isnumber(L, 2)) {
        mode = (mode_t)lua_tonumber(L, 2);
    } else {
        return luaext_error(L, "invalid mode");
    }
    if (mkdir(path, mode) == 0) {
        lua_pushboolean(L, 1);
    } else {
        errMsg = (char *)strerror(errno);
        return luaext_error(L, errMsg);
    }

    return 1;
}


static luaL_Reg libs[] = {
    {"access", luaext_access},
    {"mkdir",  luaext_mkdir},
    {"bor",    luaext_bor},
    {NULL,     NULL}
};


LUALIB_API int luaopen_luaext(lua_State* L) 
{
    const char* libName = "luaext";
    luaL_register(L, libName, libs);

    lua_pushliteral(L, LUAEXT_MODNAME);
    lua_setfield(L, -2, "_NAME");
    lua_pushliteral(L, LUAEXT_VERSION);
    lua_setfield(L, -2, "_VERSION");

    lua_newtable(L);
    lua_pushinteger(L, F_OK);
    lua_setfield(L, -2, "F_OK");
    lua_pushinteger(L, R_OK);
    lua_setfield(L, -2, "R_OK");
    lua_pushinteger(L, W_OK);
    lua_setfield(L, -2, "W_OK");
    
    lua_pushinteger(L, S_IRWXU);
    lua_setfield(L, -2, "S_IRWXU");
    lua_pushinteger(L, S_IRUSR);
    lua_setfield(L, -2, "S_IRUSR");
    lua_pushinteger(L, S_IWUSR);
    lua_setfield(L, -2, "S_IWUSR");
    lua_pushinteger(L, S_IXUSR);
    lua_setfield(L, -2, "S_IXUSR");

    lua_pushinteger(L, S_IRWXG);
    lua_setfield(L, -2, "S_IRWXG");
    lua_pushinteger(L, S_IRGRP);
    lua_setfield(L, -2, "S_IRGRP");
    lua_pushinteger(L, S_IWGRP);
    lua_setfield(L, -2, "S_IWGRP");
    lua_pushinteger(L, S_IXGRP);
    lua_setfield(L, -2, "S_IXGRP");

    lua_pushinteger(L, S_IRWXO);
    lua_setfield(L, -2, "S_IRWXO");
    lua_pushinteger(L, S_IROTH);
    lua_setfield(L, -2, "S_IROTH");
    lua_pushinteger(L, S_IWOTH);
    lua_setfield(L, -2, "S_IWOTH");
    lua_pushinteger(L, S_IXOTH);
    lua_setfield(L, -2, "S_IXOTH");

    lua_setfield(L, -2, "CONST");

    return 1;
}

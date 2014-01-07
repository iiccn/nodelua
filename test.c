#include "lua_util.h"


int main()
{
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    if (luaL_dofile(L,"node_echo.lua")) {
        const char * error = lua_tostring(L, -1);
        lua_pop(L,1);
        printf("%s\n",error);
    }
    return 0;
}

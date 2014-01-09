#include "lua_util.h"


int main(int argc,char **argv)
{
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    if (luaL_dofile(L,"node_echo.lua")) {
        const char * error = lua_tostring(L, -1);
        lua_pop(L,1);
        printf("%s\n",error);
    }

    CALL_LUA_FUNC1(L,"main",0,
                   PUSH_TABLE2(L,PUSH_STRING(L,argv[1]),
                               PUSH_NUMBER(L,atoi(argv[2])))
                   );

    printf("end here\n");
    return 0;
}

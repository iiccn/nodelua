#include "lua_util.h"
#include "msgque.h"


int main(int argc,char **argv)
{
	msgque_flush_time = 5;
	if(argc < 3)
	{
		printf("nodelua luafile mainfunction\n");
		return 0;
	}
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);
	if (luaL_dofile(L,argv[1])) {
		const char * error = lua_tostring(L, -1);
		lua_pop(L,1);
		printf("%s\n",error);
	}

	const char *start_function = argv[2];
	int arg_count = argc - 3;
	lua_getglobal(L,start_function);
	lua_newtable(L);
	int i = 0;
	for(; i < arg_count; ++i){
		PUSH_STRING(L,argv[i+3]);
		lua_rawseti(L,-2,i+1);
	}
	if(0 != lua_pcall(L,1,0,0))
	{
		const char * error = lua_tostring(L, -1);
		lua_pop(L,1);
		printf("%s\n",error);
		return 0;
	}
	printf("end here\n");
	return 0;
}

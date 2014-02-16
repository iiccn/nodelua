#include "lsock.h"
#include "core/lua_util.h"

void luasock_destroy(void *ptr)
{
    _lsock_t sock = (_lsock_t)ptr;
    if(sock->c)
        release_conn(sock->c);
    else if(sock->s != INVALID_SOCK)
        CloseSocket(sock->s);
    if(sock->sockobj)
        release_luaObj(sock->sockobj);
    free(sock);
    printf("luasocket_destroy\n");
}

_lsock_t luasock_new(struct connection *c)
{
    _lsock_t sock = calloc(1,sizeof(*sock));
    ref_init(&sock->ref,type_asynsock,luasock_destroy,1);
    if(c){
        sock->c = c;
        c->usr_ptr = sock;
    }
    return sock;
}

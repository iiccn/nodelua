CFLAGS = -g -Wall 
LDFLAGS = -lpthread -lrt -ltcmalloc
SHARED = -fPIC --shared
CC = gcc
INCLUDE = -I../luanet/kendynet/core -I../luanet/kendynet -I.. -I/usr/local/include/luajit-2.0
DEFINE = -D_DEBUG -D_LINUX

kendynet.a: \
		   ../luanet/kendynet/core/src/buffer.c \
		   ../luanet/kendynet/core/src/connection.c \
		   ../luanet/kendynet/core/src/poller.c \
		   ../luanet/kendynet/core/src/epoll.c \
		   ../luanet/kendynet/core/src/except.c \
		   ../luanet/kendynet/core/src/kendynet.c \
		   ../luanet/kendynet/core/src/msgque.c \
		   ../luanet/kendynet/core/src/netservice.c \
		   ../luanet/kendynet/core/src/rbtree.c \
		   ../luanet/kendynet/core/src/rpacket.c \
		   ../luanet/kendynet/core/src/socket.c \
		   ../luanet/kendynet/core/src/sock_util.c \
		   ../luanet/kendynet/core/src/spinlock.c \
		   ../luanet/kendynet/core/src/systime.c \
		   ../luanet/kendynet/core/src/thread.c \
		   ../luanet/kendynet/core/src/timer.c \
		   ../luanet/kendynet/core/src/uthread.c \
		   ../luanet/kendynet/core/src/refbase.c \
		   ../luanet/kendynet/core/src/asynnet.c \
		   ../luanet/kendynet/core/src/asynsock.c \
		   ../luanet/kendynet/core/src/tls.c \
		   ../luanet/kendynet/core/src/lua_util.c\
		   ../luanet/kendynet/core/src/wpacket.c
		$(CC) $(CFLAGS) -c $^ $(INCLUDE) $(DEFINE)
		ar -rc kendynet.a *.o
		rm -f *.o

nodelua:node/nodelua.c node/lsock.c kendynet.a nodelua.c
	$(CC) $(CFLAGS) -c $(SHARED) node/nodelua.c node/lsock.c $(INCLUDE) $(DEFINE) 
	$(CC) $(SHARED) -o nodelua.so nodelua.o lsock.o kendynet.a $(LDFLAGS) $(DEFINE)
	rm -f *.o
	$(CC) $(CFLAGS) -o nodelua nodelua.c kendynet.a /usr/local/lib/libluajit-5.1.a $(INCLUDE) $(LDFLAGS)	$(DEFINE) -rdynamic -ldl -lm
	
	
	
	
	

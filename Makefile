CFLAGS = -g -Wall 
LDFLAGS = -lpthread -lrt
SHARED = -fPIC --shared
CC = gcc
INCLUDE = -I../luanet/kendynet/core -I../luanet/kendynet -I..
DEFINE = -D_DEBUG -D_LINUX -DMQ_HEART_BEAT

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

nodelua:nodelua.c lsock.c kendynet.a
	$(CC) $(CFLAGS) -c $(SHARED) nodelua.c lsock.c $(INCLUDE) $(DEFINE) 
	$(CC) $(SHARED) -o nodelua.so nodelua.o lsock.o kendynet.a $(LDFLAGS) $(DEFINE)
	rm -f *.o
test:kendynet.a 	test.c
	$(CC) $(CFLAGS) -o test test.c kendynet.a $(INCLUDE) $(LDFLAGS)	$(DEFINE) -rdynamic -ldl -llua -lm		
	
	
	
	
	

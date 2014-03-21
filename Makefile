CFLAGS = -O2 -g -Wall 
LDFLAGS = -lpthread -lrt -ltcmalloc
SHARED = -fPIC --shared
CC = gcc
INCLUDE = -I../KendyNet/core -I../KendyNet -I.. -I../KendyNet/deps/luajit-2.0/src
DEFINE = -D_DEBUG -D_LINUX -DMQ_HEART_BEAT

kendynet.a: \
		   ../KendyNet/core/src/buffer.c \
		   ../KendyNet/core/src/connection.c \
		   ../KendyNet/core/src/poller.c \
		   ../KendyNet/core/src/epoll.c \
		   ../KendyNet/core/src/except.c \
		   ../KendyNet/core/src/kendynet.c \
		   ../KendyNet/core/src/msgque.c \
		   ../KendyNet/core/src/netservice.c \
		   ../KendyNet/core/src/rbtree.c \
		   ../KendyNet/core/src/rpacket.c \
		   ../KendyNet/core/src/socket.c \
		   ../KendyNet/core/src/sock_util.c \
		   ../KendyNet/core/src/spinlock.c \
		   ../KendyNet/core/src/systime.c \
		   ../KendyNet/core/src/thread.c \
		   ../KendyNet/core/src/timer.c \
		   ../KendyNet/core/src/uthread.c \
		   ../KendyNet/core/src/refbase.c \
		   ../KendyNet/core/src/log.c \
		   ../KendyNet/core/asynnet/src/asynnet.c \
		   ../KendyNet/core/asynnet/src/asynsock.c \
		   ../KendyNet/core/asynnet/src/msgdisp.c \
		   ../KendyNet/core/asynnet/src/asyncall.c \
		   ../KendyNet/core/src/atomic_st.c \
		   ../KendyNet/core/src/tls.c \
		   ../KendyNet/core/src/lua_util.c\
		   ../KendyNet/core/src/lua_util.c\
		   ../KendyNet/core/src/kn_string.c\
		   ../KendyNet/core/src/hash_map.c\
		   ../KendyNet/core/src/minheap.c\
		   ../KendyNet/core/src/lookup8.c\
		   ../KendyNet/core/src/wpacket.c
		$(CC) $(CFLAGS) -c $^ $(INCLUDE) $(DEFINE)
		ar -rc kendynet.a *.o
		rm -f *.o

nodelua:node/nodelua.c node/lsock.c kendynet.a nodelua.c
	$(CC) $(CFLAGS) -c $(SHARED) node/nodelua.c node/lsock.c $(INCLUDE) $(DEFINE) 
	$(CC) $(SHARED) -o nodelua.so nodelua.o lsock.o kendynet.a $(LDFLAGS) $(DEFINE)
	rm -f *.o
	$(CC) $(CFLAGS) -o nodelua nodelua.c kendynet.a ../KendyNet/deps/luajit-2.0/src/libluajit.a $(INCLUDE) $(LDFLAGS)	$(DEFINE) -rdynamic -ldl -lm
	
	
	
	
	

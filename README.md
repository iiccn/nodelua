使用过go的同学可能都会感觉go的网络接口非常方便，提供同步的处理方式，结合goroutine实现并发.

nodelua正是结合了异步网络和lua coroutine实现的类似go的网络处理接口.与go不同的是多个lua coroutine
不能像goroutine那样在多个处理器上并发执行.


nodelua的网络层使用了我另外一个项目中的kendynet,运行在单独的线程中，网络和lua之间通过消息队列通信.
测试效率不比C的差多少（使用luagit运行，如果没有luagit运行效率只有C版本的不到一半）

------------echoserver-----------------

	require("nodelua")
	dofile("scheduler.lua")
	
	function doio(s)
	    while true do
	        local data,err = s:recv()
	        if err == "disconnect" then
	            return
	        else
	            s:send(data)
	        end
	    end
	end
	
	function listen_fun(l)
	    while true do
	        local s,err = l:accept()
	        if s then
	            node_spwan(s,doio) --spwan a light process to do io
	        elseif err == "stop" then
	            return
	        end
	    end
	end
	
	function main()		
	    local l,err = tcp_listen("127.0.0.1",8010)
	    if l then
	        node_spwan(l,listen_fun) --spwan a light process to do accept
	    end
	    node_loop()
	end
	
	main()


--------------echo client------------------

	require("nodelua")
	dofile("scheduler.lua")
	
	function connect_fun(l)
	    local sock,err = tcp_connect("127.0.0.1",8010,30)
	    if sock then
	        while true do
	            local data,err = sock:recv()
	            if err == "disconnect" then
	                return
	            else
	                sock:send(data)
	            end
	        end
	    end
	end
	
	function main()
	    node_spwan(nil,connect_fun) --spwan a light process to do accept
	    node_loop()
	end
	
	main()


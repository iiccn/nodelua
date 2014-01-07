lua coroutine实现的网络框架.使用方式类似go语言,利用coroutine提供阻塞式的io接口.
网络处理在C中实现由一个单独的线程处理,C和lua之间通过一个消息队列通信.

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


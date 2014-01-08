--echoserver范例

require("nodelua")
dofile("node/scheduler.lua")
function doio(s)
    print("doio")
    while true do
        local data,err = s:recv()
        if err == "disconnected" then
            print("a socket disconnect")
            return
        elseif err == "timeout" then
            print("recv timeout")
            s:close()
            return
        else
			print("recvmsg")
			print(data)
            s:send(data)
        end
    end
end

function listen_fun(l)
    print("listen_fun haha")
    while true do
        local s,err = l:accept()
        print(err)
        if s then
            node_spwan(s,doio) --spwan a light process to do io
        elseif err == "stop" then
            return
        end
    end
end

--function main(arg)
function main()
    local l,err = tcp_listen(arg[1],arg[2])
    if err then
            print("listen error")
            return
    end
    print("listen ok")
    if l then
        node_spwan(l,listen_fun) --spwan a light process to do accept
    end
    node_loop()
    print("see you!")
    exit(0)
end

main()

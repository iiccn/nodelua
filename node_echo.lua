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
        else
            s:send(data)
        end
    end
end

function listen_fun(l)
    print("listen_fun")
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
    --local l,err = tcp_listen("127.0.0.1",8010)--arg[1],arg[2])
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
end

main()

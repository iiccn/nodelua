--echoserver范例

require("nodelua")
dofile("node/scheduler.lua")

packet_recv_count = 0
packet_recv_size = 0
client_count = 0

function doio(s)
	client_count = client_count + 1
	--print("doio")
    while true do
        local data,err = s:recv(10000)
        if err then
			print("a socket disconnect " .. err)
			s:close()
			client_count = client_count - 1
            return
        else
			--print("recv packet")
			packet_recv_count = packet_recv_count + 1
			--print("recv packet 1")
			--packet_recv_size = packet_recv_size + string.len(data)
			--print("recv packet 2")
            s:send(data)
            ReleasePacket(data)
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

function main(arg)		
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

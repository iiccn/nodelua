--echoserver范例

require("nodelua")
dofile("node/scheduler.lua")

packet_recv_count = 0
packet_recv_size = 0
client_count = 0

function doio(s)
	client_count = client_count + 1
	while true do
		local data,err = s:recv(10000)
		if err then
			print("a socket disconnect " .. err)
			s:close()
			client_count = client_count - 1
			return
		else
			packet_recv_count = packet_recv_count + 1
			s:send(data)
			ReleasePacket(data)
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
	spawn(function()
		print("listen_fun")
		while true do
			local s,err = l:accept()
			if s then
				spawn(doio,s) --spwan a light process to do io
			elseif err == "stop" then
				return
			end
		end
	end)
	node_loop()
	print("see you!")
end

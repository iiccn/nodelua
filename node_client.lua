require("nodelua")
dofile("node/scheduler.lua")

ip = nil
port = nil

local send_data = [[hellohellohellohello]]

function connect_fun(l)
    local sock,err = tcp_connect(ip,port,30000)
    if sock then
        print("connect sucessful")
        sock:send(send_data)
        while true do
            local data,err = sock:recv()
            if err then
				sock:close()
                return
            else
                sock:send(data)
            end
        end
    end
end

function main(arg)
	ip = arg[1]
	port = tonumber(arg[2])
	print(ip)
	print(port)
	print(arg[3])
	local count = tonumber(arg[3])
	while count > 0 do
		node_spwan(nil,connect_fun) --spwan a light process to do accept
		count = count - 1
    end
    node_loop()
    print("see you!")
end

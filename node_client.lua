require("nodelua")
dofile("node/scheduler.lua")

ip = nil
port = nil

function connect_fun(l)
    local sock,err = tcp_connect(ip,port,30)
    if sock then
		print("connect sucessful")
        sock:send("hello")
        while true do
            local data,err = sock:recv()
            if err == "disconnect" then
                return
            else
				print(data)
                sock:send(data)
            end
        end
    end
end
--function main(arg)
function main()
	ip = arg[1]
	port = tonumber(arg[2])
	local count = 1--tonumber(arg[3])
	while count > 0 do
		node_spwan(nil,connect_fun) --spwan a light process to do accept
		count = count - 1
    end
    node_loop()
    print("see you!")
    exit(0)
end

main()

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

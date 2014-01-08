dofile("node/queue.lua")
dofile("node/light_process.lua")

socket = {
        type = nil,     -- data or listen
        msgque = nil,
        csocket = nil,
        lprocess = nil,
        index,
}


sock_index = 1

sock_container = {}

function socket:hello()
    print("i'm socket")
end

function socket:accept()

    print("accept 1")
    if not self.csocket then
        print("accept 2")
        return nil,"disconnected"
    elseif self.type == "data" then
        print("accept 3")
        return nil,"accept error"
    else
        print("accept 4")
        if self.msgque:is_empty() then
            if not self.lprocess then
                self.lprocess = GetCurrentLightProcess()
            end
            --block
            print("accept before block")
            print(self.lprocess)
            print(self)
            Block()
        end
        local msg = self.msgque:pop()
        print("accept 5")
        if msg[1] ~= "newconnection" then
            print("error")
        else
            print("a new connection")
            return sock_container[msg[2]]
        end
    end
end


function socket:recv(timeout)
    if not self.csocket then
        return nil,"disconnected"
    elseif self.type == "data" then
        if self.msgque:is_empty() then
            if not self.lprocess then
                self.lprocess = GetCurrentLightProcess()
            end
            --block
            Block(timeout)
        end
        print("recv wakeup")
        local msg = self.msgque:pop()
        if not msg then
            return nil,"timeout"
        end

        if msg[1] ~= "packet" and msg[1] ~= "disconnected" then
                print("error" .. msg[1])
        else
                return msg[2],msg[3]
        end
		
    else
        return nil,"not data socket"
    end
end

function socket:send(data)
    if not self.csocket then
        return nil,"disconnected"
    elseif self.type == "data" then
        SendPacket(self.csocket,data)
    else
        return nil,"not data socket"
    end
end

function socket:pushmsg(msg)
    self.msgque:push(msg)
    print("socket:pushmsg")
    print(self.lprocess)
    print(self.lprocess.status)
    if self.lprocess and self.lprocess.status == "block" then
		WakeUp(self.lprocess)
    end
end

function socket:finalize()

end

function socket:close()
    if self.index > 0 then
        sock_container[self.index] = nil
        self.index = 0
    end
    if not self.csocket then
        return "disconnected"
    end
    Close(self.csocket)
    self.csocket = nil
end

function socket:new()
    local o = {}
    self.__gc = socket.finalize
    self.__index = self
    setmetatable(o, self)
    o.msgque = queue:new()
    o.index = sock_index
    sock_index = sock_index + 1
    sock_container[o.index] = o
    return o
end

--for c function to call
function create_socket(csocket,type)
    print("create_socket")
    local n = socket:new()
    n.type = type
    --n.lprocess = GetCurrentLightProcess()
    n.csocket = csocket
    return n.index
end

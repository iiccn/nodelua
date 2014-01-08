dofile("node/queue.lua")
dofile("node/light_process.lua")

socket = {
        type = nil,     -- data or listen
        msgque = nil,
        csocket = nil,
        lprocess = nil,
}

function socket:accept()

    if not self.csocket then
        return nil,"disconnected"
    elseif self.type == "data" then
        return nil,"accept error"
    else
        if self.msgque:is_empty() then
            if not self.lprocess then
                self.lprocess = GetCurrentLightProcess()
            end
            --block
            Block()
        end
        local msg = self.msgque:pop()
        if msg[1] ~= "newconnection" then
			print("error")
        else
			print("a new connection")
			return msg[2]
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
        local msg = self.msgque:pop()
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
    if self.lprocess and self.lprocess.status == "block" then
		WakeUp(self.lprocess)
    end
end

function socket:finalize()

end

function socket:close()
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
    return o
end

--for c function to call
function create_socket(csocket,type)
    local n = socket:new()
    n.type = type
    n.lprocess = GetCurrentLightProcess()
    n.csocket = csocket
    return n
end

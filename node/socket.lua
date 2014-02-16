dofile("node/queue.lua")
dofile("node/light_process.lua")

base_socket = {
	msgque = nil,
	csocket = nil,
	lprocess = nil,
}


function base_socket:pushmsg(msg)
    self.msgque:push(msg)
    --print("socket:pushmsg")
    if self.lprocess and self.lprocess.status == "block" then
		WakeUp(self.lprocess)
    end
end

function base_socket:finalize()
	print("base_socket:finalize")
end

function base_socket:close()
    if self.csocket then
        print("close")
        Close(self.csocket)
        self.csocket = nil
    else
        return "disconnected"
    end
end

function base_socket:new()
    local o = {}
    self.__gc = base_socket.finalize
    self.__index = self
    setmetatable(o, self)
    return o
end

function base_socket:init()
    self.msgque = queue:new()
    self.lprocess = GetCurrentLightProcess()
end


data_socket = base_socket:new()

function data_socket:recv(timeout)        
    if self.csocket then
        if self.msgque:is_empty() then
            if not self.lprocess then
                self.lprocess = GetCurrentLightProcess()
            end
            --block
            Block(timeout)
        end
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
        return nil,"disconnected"
    end
end

function data_socket:send(data)
	--print("data_socket:send 1")
    if self.csocket then
		--print("data_socket:send 2")
        SendPacket(self.csocket,data)
    else
        return nil,"disconnected"
    end
end

function data_socket:new()
    local o = {}
    self.__gc = base_socket.finalize
    self.__index = self
    setmetatable(o, self)
    o:init()
    return o
end

acceptor = base_socket:new()

function acceptor:accept()
    if self.csocket then
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
    else
        return nil,"disconnected"
    end
end

function acceptor:new()
    local o = {}
    self.__gc = base_socket.finalize
    self.__index = self
    setmetatable(o, self)
    o:init()
    return o
end

--for c function to call
function create_socket(csocket,type)
    --print("create_socket")
    local n
    if type == "data" then
            n = data_socket:new()
    elseif type == "acceptor" then
            n = acceptor:new()
    else
            n = base_socket:new()
            n:init()
    end
    n.csocket = csocket
    --print(csocket)
    return n
end

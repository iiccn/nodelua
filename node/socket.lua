dofile("node/queue.lua")
dofile("node/light_process.lua")

base_socket = {
	msgque = nil,
	csocket = nil,
	lprocess = nil,
	index,
	release_index,
}


sock_index = 0
sock_container = {}
sock_index_pool = queue:new()


function base_socket:pushmsg(msg)
    self.msgque:push(msg)
    --print("socket:pushmsg")
    if self.lprocess and self.lprocess.status == "block" then
		WakeUp(self.lprocess)
    end
end

function base_socket:finalize()
	print("base_socket:finalize")
	sock_index_pool:push(self.release_index)
end

function base_socket:close()
    if self.index > 0 then
		print("close")
        sock_container[self.index] = nil
        self.release_index = self.index
		self.index = 0
		Close(self.csocket)
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
	if sock_index_pool:is_empty() then
		sock_index = sock_index + 1
		sock_index_pool:push(sock_index)
	end
	self.lprocess = GetCurrentLightProcess()
    self.index = sock_index_pool:pop()
end


data_socket = base_socket:new()

function data_socket:recv(timeout)        
    if self.index > 0 then
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
    if self.index > 0 then
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
    if self.index > 0 then
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
            return sock_container[msg[2]]
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
    print("create_socket")
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
	sock_container[n.index] = n
    return n.index
end

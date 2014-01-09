dofile("node/timer.lua")
dofile("node/light_process.lua")
dofile("node/socket.lua")

scheduler =
{
    pending_add,  --�ȴ����ӵ���б��е�coObject
    timer,
    CoroCount,
    current_lp
}

function scheduler:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function scheduler:init()
    self.m_timer = timer:new()
    self.pending_add = {}
    self.current_lp = nil
    self.CoroCount = 0
end

--���ӵ���б���
function scheduler:Add2Active(lprocess)
    if lprocess.status == "actived" then
        return
    end
    lprocess.status = "actived"
    table.insert(self.pending_add,lprocess)
end

function scheduler:Block(ms)
    local lprocess = self.current_lp
    if ms and ms > 0 then
        local nowtick = GetSysTick()
        lprocess.timeout = nowtick + ms
        if lprocess.index == 0 then
            self.m_timer:Insert(lprocess)
        else
            self.m_timer:Change(lprocess)
        end
    end
    lprocess.status = "block"
    coroutine.yield(lprocess.croutine)
    --�������ˣ�������г�ʱ�ڶ����У�������Ҫ������ṹ�ŵ�����ͷ��������ɾ��
    if lprocess.index ~= 0 then
        lprocess.timeout = 0		
        self.m_timer:Change(lprocess)
        self.m_timer:PopMin()
    end
end


--˯��ms
function scheduler:Sleep(ms)
    local lprocess = self.current_lp
    if ms and ms > 0 then
        lprocess.timeout = GetSysTick() + ms
        if lprocess.index == 0 then
            self.m_timer:Insert(lprocess)
        else
            self.m_timer:Change(lprocess)
        end
        lprocess.status = "sleep"
    else
        lprocess.status = "yield"
    end
    coroutine.yield(lprocess.croutine)
end

--��ʱ�ͷ�ִ��Ȩ
function scheduler:Yield()
    self:Sleep(0)
end


--������ѭ��
function scheduler:Schedule()
    local runlist = {}
    --��pending_add������coObject���ӵ���б���
    for k,v in pairs(self.pending_add) do
        table.insert(runlist,v)
    end

    self.pending_add = {}
    local now_tick = GetSysTick()
    for k,v in pairs(runlist) do
        self.current_lp = v
        coroutine.resume(v.croutine,v)
        self.current_lp = nil
        if v.status == "yield" then
            self:Add2Active(v)
        elseif v.status == "dead" then
			print("a light process dead")
		end
    end
    runlist = {}
    --������û��timeout���˳�
    local now = GetSysTick()
    while self.m_timer:Min() ~=0 and self.m_timer:Min() <= now do
        local lprocess = self.m_timer:PopMin()
        if lprocess.status == "block" or lprocess.status == "sleep" then
            self:Add2Active(lprocess)
        end
    end
end

function scheduler:WakeUp(lprocess)
    self:Add2Active(lprocess)
end

global_sc = scheduler:new()
global_sc:init()

function Yield()
    global_sc:Yield()
end

function Sleep(ms)
    global_sc:Yield(ms)
end

function Block(ms)
    global_sc:Block(ms)
end

function WakeUp(lprocess)
   global_sc:WakeUp(lprocess)
end

function GetCurrentLightProcess()
    return global_sc.current_lp
end

function lp_start_fun(lp)
    print("lp_start_fun")
	global_sc.CoroCount = global_sc.CoroCount + 1
	lp.start_func(lp.ud)
	lp.status = "dead"
	lp.ud = nil
	global_sc.CoroCount = global_sc.CoroCount - 1
	print("end lp_start_fun")
end

function node_spwan(ud,mainfun)
    print("node_spwan")
    local lprocess = light_process:new()
    lprocess.croutine = coroutine.create(lp_start_fun)
    lprocess.ud = ud
	lprocess.start_func = mainfun
    global_sc:Add2Active(lprocess)
end

function node_process_msg(msg)
    local recver = msg[1]
	if not recver then
		return
	end
	local type = msg[2]
	if type == "packet" then
		recver:pushmsg({"packet",msg[3],nil})
	elseif type == "newconnection" then
		recver:pushmsg({"newconnection",msg[3]})
	elseif type == "disconnected" then
		recver.csocket = nil
		recver:pushmsg({"disconnected",nil,msg[3]})
	elseif type == "connect_failed" then
                print(recver)
		recver:pushmsg({"connect_failed",nil,msg[3]})
	end
end

function node_loop(ms)
--[[    global_sc:Schedule()
	local msg,err = PeekMsg(ms)
	if msg then
		node_process_msg(msg)
	end
	return err
]]--	
	local lasttick = GetSysTick()
	while true do
        global_sc:Schedule()
        local msg,err = PeekMsg(50)
		if err and err == "stoped" then
		   return
		end
		if msg then
		   node_process_msg(msg)
		end
		local tick = GetSysTick()
		if tick - 1000 >= lasttick then
			if packet_recv_count then
				print("packet_recv_count:" .. packet_recv_count .. 
                                " packet_recv_size:" .. packet_recv_size/1024/1024)
				packet_recv_count = 0
				packet_recv_size = 0
			end
			lasttick = tick
		end		
    end
end

function tcp_listen(ip,port)
    local l,err = Listen(ip,port)
    print(l)
    if l ~= nil then
        return l,nil
    else
        return nil,err
    end
end

function tcp_connect(ip,port,timeout)
    local connect_sock = create_socket(nil,"connector")
    print("timeout " .. timeout)
    Connect(ip,port,timeout,connect_sock)
    Block()
    local msg = connect_sock.msgque:pop()
    connect_sock:close()
    if msg[1] == "connect_failed" then
           return nil,msg[3]
    elseif msg[1] == "newconnection" then
           return msg[2],nil
    else
           return nil,"fatal error"
    end
end

dofile("timer.lua")
difile("light_process.lua")

scheduler =
{
    pending_add,  --等待添加到活动列表中的coObject
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

--添加到活动列表中
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
    --被唤醒了，如果还有超时在队列中，这里需要将这个结构放到队列头，并将其删除
    if lprocess.index ~= 0 then
        sock.timeout = 0
        self.m_timer:Change(lprocess)
        self.m_timer:PopMin()
    end
end


--睡眠ms
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

--暂时释放执行权
function scheduler:Yield()
    self:Sleep(0)
end


--主调度循环
function scheduler:Schedule()
    local runlist = {}
    --将pending_add中所有coObject添加到活动列表中
    for k,v in pairs(self.pending_add) do
        table.insert(runlist,v)
    end

    self.pending_add = {}
    local now_tick = GetSysTick()
    for k,v in pairs(runlist) do
        self.current_lp = v
        coroutine.resume(v.croutine,v.ud)
        self.current_lp = nil
        if v.status == "yield" then
            self:Add2Active(v)
        end
    end
    runlist = {}
    --看看有没有timeout的纤程
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
    global_sc:Block()
end

function WakeUp(lprocess)
   global_sc:WakeUp(lprocess)
end

function GetCurrentLightProcess()
    return global_sc.current_lp
end

function node_spwan(ud,mainfun)
    local lprocess = light_process:new()
    lprocess.croutine = coroutine.create(mainfun)
    lprocess.ud = ud
    global_sc:Add2Active(lprocess)
end

function node_process_msg(msg)
    local recver = msg[0]
    local type = msg[1]
    if type == "packet" then
        recver:pushmsg({"packet",msg[3],nil})
    elseif type == "newconnection" then
        recver:pushmsg({"newconnection",msg[3]})
    elseif type == "disconnected" then
        recver.csocket = nil
        recver:pushmsg({"disconnected",nil,msg[3]})
    elseif type == "connect_failed" then
        recver:pushmsg({"connect_failed",nil,msg[3]})
    end
end

function node_loop()
    global_sc:Schedule()
    node_process_msg(PeekMsg(50))
end

function tcp_listen(ip,port)
    return Listen(ip,port)
end

function tcp_connect(ip,port,timeout)
    local connect_sock = Connect(ip,port,timeout)
    if connect_sock.msgque:is_empty() then
        if ~connect_sock.lprocess then
            connect_sock.lprocess = GetCurrentLightProcess()
        end
        --block
        Block()
    end
    local msg = connect_sock.msgque:pop()
    if msg[1] = "connect_failed" then
           return nil,msg[3]
    elseif msg[1] = "newconnection" then
           return msg[1],nil
    else
           return nil,"fatal error"
    end
end


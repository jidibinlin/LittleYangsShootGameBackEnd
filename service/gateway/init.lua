local skynet = require "skynet"
local serviceConfig = require "serviceConfig"
local s = require "service"
local pb=require "pb"
local protoc = require "protoc"
local socket = require "skynet.socket"
local idToName = require "protoConfig"

--local proto3 = true
-- protobuf
local pc = protoc.new()
pc:addpath(skynet.getenv("proto_path"))
-- login relate
pc:loadfile("gateway.proto")
pc:loadfile("agent.proto")
conns = {} -- [fd]=conn
players = {} -- [playerid] = gateplayer

function conn()
   local m ={
      fd=nil,
      playerId = nil
   }
   return m
end

local disconnect = function (fd)
   local c = conns[fd]
   if not c then
      return
   end

   local playerid = c.playerid
   if not playerid then
      return
   else
      players[playerid]=nil
      local reason = "lost connection"
      skynet.call("agentmgr","lua","reqkick",playerid,reason)
      skynet.error(playerid,reason)
   end
end

function gatePlayer()
   local m ={
      playerid = nil,
      agent = nil,
      con = nil,
   }
   return m
end

local function tablePrint(msg)
   for key, value in pairs(msg) do
      if type(value) == "table" then
         print(key,tablePrint(value))
         --tablePrint(value)
      else
         print(key,value)
      end
   end
end

local msg_unpack = function(id,recv,fd)

   local state, msg = pcall(pb.decode,idToName[id],recv)
   --tablePrint(msg)
   if not state then
      disconnect(fd)
      socket.close(fd)
      return
   end
   return msg.cmd,msg
end

local msg_pack=function (msg)
   --local data = pb_buf.new(buf)
   --tablePrint(msg)
   local id = msg.id
   local buf = pb.encode(idToName[id],msg)
   local len = #buf
   skynet.error("msg",msg.cmd,"len",len)
   len = string.pack(">I4",len)
   id = string.pack(">I4",id)
   local send = len..id..buf
   --return pb_buf.result(data)
   return send
end

s.resp.send_by_fd = function (source,fd,msg)
   if not conns[fd] then
      skynet.error("没找到fd")
      return
   end
   local buff = msg_pack(msg)
   socket.write(fd,buff)
end

s.resp.send = function (source,playerid,msg)
   if not msg then
      return
   end

   local gplayer= players[playerid]
   if gplayer ==nil then
      return
   end
   local c = gplayer.conn
   if c==nil then
      return
   end
   s.resp.send_by_fd(nil,c.fd,msg)
end

s.resp.sure_agent = function (source,fd,playerid,agent)
   local conn = conns[fd]
   if not conn then
      skynet.call("agentmgr","lua","reqkick",playerid,"未完成登录即下线")
      return false
   end
   conn.playerid = playerid
   local gplayer = gatePlayer()
   gplayer.playerid = playerid
   gplayer.agent = agent
   gplayer.conn = conn
   players[playerid]=gplayer
   return true
end


s.resp.kick = function (source,playerid)
   skynet.error("gateway kick:",playerid)
   local gplayer = players[playerid]
   if not gplayer then
      return
   end
   local c= gplayer.conn
   players[playerid] = nil
   if not c then
      return
   end
   conns[c.fd]=nil
   disconnect(c.fd)
   socket.close(c.fd)
end

local process_msg = function (fd,id,msgblock)
   local cmd,msg = msg_unpack(id,msgblock,fd)
   skynet.error("procesed message: ",cmd," gateway-",144)
   local conn = conns[fd]
   local playerid = conn.playerid
   if not playerid then
      local node = skynet.getenv("node")
      local nodecfg = serviceConfig[node]
      local loginid = math.random(1,#nodecfg.login)
      local login = "login"..loginid
      skynet.send(login,"lua","client",fd,cmd,msg)
   else
      local gplayer = players[playerid]
      local agent = gplayer.agent
      skynet.send(agent,"lua","client",cmd,msg)
   end
end

local recv_loop = function (fd)
   socket.start(fd)
   while true do
      local head = socket.read(fd,8)
      local status,len,id,_ =pcall(string.unpack,">I4I4",head)

      if not status then
         disconnect(fd)
         socket.close(fd)
         return
      end

      local recv = socket.read(fd,tonumber(len))
      if recv then
         skynet.error("proto id = "..tostring(id))
         process_msg(fd,id,recv)
      else
         skynet.error("skynet close"..fd)
         disconnect(fd)
         socket.close(fd)
         return
      end
   end
end


local connect =  function(fd,addr)
   print("connect from"..addr.." "..fd)
   local c = conn()
   conns[fd]=c
   c.fd=fd
   skynet.fork(recv_loop,fd)
end

function s.init()
   local node = skynet.getenv("node")
   local nodecfg = serviceConfig[node]
   local port = nodecfg.gateway[s.id].port
   local listenfd = socket.listen("0.0.0.0",port)
   skynet.error("Listening socket: ","0.0.0.0",port)
   socket.start(listenfd,connect)
end

s.start(...)

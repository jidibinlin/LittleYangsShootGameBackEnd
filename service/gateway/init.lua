local skynet = require "skynet"
local serviceConfig = require "serviceConfig"
local s = require "service"
local pb=require "pb"
local protoc = require "protoc"
local socket = require "skynet.socket"
local idToName,nameToId = require "protoConfig"

--local proto3 = true
-- protobuf
local pc = protoc.new()
pc:addpath(skynet.getenv("proto_path"))
-- login relate
pc:loadfile("gateway.proto")
conns = {} -- [fd]=conn
players = {} -- [playerid] = gateplayer


function conn()
   local m ={
      fd=nil,
      playerId = nil
   }
   return m
end

function gatePlayer()
   local m ={
      playerid = nil,
      agent = nil,
      con = nil,
   }
   return m
end

local msg_unpack = function(id,recv)
   print(recv)
   local msg = pb.decode(idToName[id],recv)
   --Debug
   -- for key, value in pairs(msg) do
   -- print(key,value)
   -- end
   --print("msg unpack:"..table.concat(msg,","))
   return msg.cmd,msg
end

local msg_pack=function (id,msg)
   --local data = pb_buf.new(buf)

   local buf = pb.encode(idToName[id],msg)
   local len = #buf
   len = string.pack(">I4",len)
   id = string.pack(">I4",id)
   local send = len..id..buf
   print(send)
   --return pb_buf.result(data)
   return send
end


-- local msg_pack = function (msg)
--    local type = msg.cmd
--    local stat,size = pb.load("login."..type)
--    local buff = string.pack(">h",size)
--    buff = buff..pb.encode("login."..type,msg)
--    return buff
-- end

s.resp.send_by_fd = function (source,fd,msg)
   if not conns[fd] then
      return
   end
   local buff = msg_pack(nameToId["gateway."..msg.cmd],msg)
   skynet.error("send "..fd.." {"..table.concat(msg,",").."}")
   socket.write(fd,buff)
end

s.resp.send = function (source,playerid,msg)
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
      local reason = "fall down"
      skynet.call("agentmgr","lua","reqkick",playerid,reason)
   end
end

s.resp.kick = function (source,playerid)
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
   local cmd,msg = msg_unpack(id,msgblock)
   --skynet.error("recv ".."{"..table.concat(msg,",").."}")
   local conn = conns[fd]
   local playerid = conn.playerid
   if not playerid then
      local node = skynet.getenv("node")
      local nodecfg = serviceConfig[node]
      local loginid = math.random(1,#nodecfg.login)
      local login = "login"..loginid

      skynet.error("Login ..........",login,cmd,msg)

      skynet.send(login,"lua","client",fd,cmd,msg)
   else
      local gplayer = players[playerid]
      local agent = gplayer.agent
      skynet.send(agent,"lua","client",cmd,msg)
   end
end

local recv_loop = function (fd)
   socket.start(fd)
   skynet.error("socket connected"..fd)
   while true do
      local head = socket.read(fd,8)
      local len,id,_ =string.unpack(">I4I4",head)
      local recv = socket.read(fd,tonumber(len))
      if recv then
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

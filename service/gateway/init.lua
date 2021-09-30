local skynet = require "skynet"
local serviceConfig = require "serviceConfig"
local s = require "service"

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

local recv_loop = function (fd)
   socket.start(fd)
   skynet.error("socket connected"..fd)
   local readbuff = ""
   while true do
      local recvstr = socket.read(fd)
      if recvstr then
         readbuff = readbuff..recvstr
         readbuff = process_buff(fd,readbuff)
      else
         skynet.error("skynet close"..fd)
         disconnect(fd)
         socket.close(fd)
         return
      end
   end
   end


   local connect =  function(fd,adrr)
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

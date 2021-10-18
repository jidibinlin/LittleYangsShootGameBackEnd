local skynet = require "skynet"
local s= require "service"
local curNode = skynet.getenv("node")
local serviceConfig = require "serviceConfig"

s.client={}
s.gate=nil

s.snode = nil
s.sname = nil

s.resp.client = function (source,cmd,msg)
   skynet.error("agent client dispatch "..cmd .." agent-",14)

   if not s.gate then
      s.gate = source
   end
   if s.client[cmd] then
      local ret_msg = s.client[cmd](msg,s.gate)
      if ret_msg then
         skynet.send(s.gate,"lua","send",s.id,ret_msg)
      end
   else
      skynet.error("s.resp.client fial",cmd)
   end
end

s.resp.enterScene = function(source,snode,sname)
   s.snode = snode
   s.sname = sname
   return true
end

s.client.pvp = function ()
   local stat =  s.call(serviceConfig.agentmgr.node,"agentmgr","pvp",s.id)
   if stat then
      return {id =8 ,cmd = "surePvp"}
   end
end

s.client.broadcastCtoS = function (msg)
   s.send(s.snode,s.sname,"broadcastCtoS",s.id,msg)
end

s.client.leaveScene = function (msg)
   skynet.error("require leave scene")
   if not s.name then
      return
   end
   s.call(s.snode,s.sname,"leave",s.id)
   s.snode = nil
   s.sname = nil

   if not msg.reason then
      msg.reason = "request leave scene success"
   end
   --TODO : return proto
   return {id = 9,cmd = "respLeaveScene",reason = msg.reason}
end

s.resp.send = function (source,msg)
   skynet.send(s.gate,"lua","send",s.id,msg)
end

s.resp.kick = function (source)
   skynet.error("agent kick")
   skynet.sleep(200
   )
end


s.resp.exit = function (source)
   skynet.error("skynet agent exit")
   skynet.exit()
end

s.init = function ()
   skynet.sleep(200)
end

s.start(...)

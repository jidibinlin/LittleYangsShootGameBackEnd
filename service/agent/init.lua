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
   s.gate = source
   if s.client[cmd] then
      local ret_msg = s.client[cmd](msg,source)
      if ret_msg then
         skynet.send(source,"lua","send",s.id,ret_msg)
      end
   else
      skynet.error("s.resp.client fial",cmd)
   end
end

local function random_scene()
   skynet.error("随机场景中")
   local nodes = {}
   for index, value in pairs(serviceConfig.scene) do
      table.insert(nodes,index)
      if serviceConfig.scene[curNode] then
         table.insert(nodes,curNode)
      end
   end
   print("nodes number=",#nodes)

   local key = math.random(1,#nodes)
   local scenenode = nodes[key]

   local scenelist = serviceConfig.scene[scenenode]
   local key = math.random(1,#scenelist)
   local sceneid = scenelist[key]
   return scenenode,sceneid
end


s.client.enterScene = function(msg)
   skynet.error("请求进入场景")
   if s.sname then
      return {id=3,cmd="sureEnterScene",stat=2,reason="already in the scene"}
   end
   local snode,sid = random_scene()
   local sname ="scene"..sid
   skynet.error("player id: ",s.id)
   local isok = s.call(snode,sname,"enterScene",s.id,curNode,skynet.self())


   if not isok then
      s.snode = snode
      s.sname = sname
      return {id=3,cmd="sureEnterScene",stat=1,reason="enter scene successed"}
   end
   return nil
end

s.client.broadcastCtoS = function (msg)
   s.send(s.snode,s.sname,"broadcastCtoS",s.id,msg)
end


s.leave_scene = function ()
   skynet.error("离开场景")
   if not s.name then
      return
   end
   s.call(s.snode,s.sname,"leave",s.id)
   s.snode = nil
   s.sname = nil
end

-- s.client.work = function (msg)
--    s.leave_scene()
--    return {"work:"..msg.cmd}
-- end

s.resp.send = function (source,msg)
   skynet.send(s.gate,"lua","send",s.id,msg)
end


s.resp.kick = function (source)
   skynet.error("agent kick")
   skynet.sleep(200)
end


s.resp.exit = function (source)
   skynet.error("skynet agent exit")
   skynet.exit()
end

s.init = function ()
   skynet.sleep(200)
end

s.start(...)

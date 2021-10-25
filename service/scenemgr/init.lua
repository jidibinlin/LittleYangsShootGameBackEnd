local skynet = require "skynet"
local s = require "service"
local serviceConfig = require "serviceConfig"
local currNode = skynet.getenv("node")

local nodes = serviceConfig.cluster
local sceneNode={}

function scene()
   local m = {
      id = nil,
      --name = nil,
      status = nil,
      node = nil,
      srv = nil,
   }
   return m
end

STATUS = {
   GAMING = 1,
   WAIT = 2,
}


local createScene = function (node)
   local id = nil

   local scenes = sceneNode[node]

   if next(scenes) == nil then
      id = 1
   else
      id = #scenes+1
   end
   --if node == currNode then
   --srv = skynet.newservice("scene","scene",id)
   --else
   local srv = s.call(node,"nodemgr","newservice","scene","scene",id)
   --end
   if not srv then
      skynet.error("create scene on ",node,"failed")
      return false
   end
   --local srv = skynet.newservice("scene","scene",id)
   --skynet.name(node.."scene"..id,srv)
   local tmp = scene()
   tmp.id = id
   tmp.node = node
   --scene.name = node.."scene"..id
   tmp.srv = srv
   tmp.status = STATUS.WAIT
   table.insert(scenes,id,tmp)
end

s.resp.createScene = function (source)
   skynet.error("createScene ---------------")
   for key, node in pairs(nodes) do
      sceneNode[key]={}
   end
   for key, node in pairs(nodes) do
      for i=1,10 do
         createScene(key)
      end
   end
end

s.resp.enterScene = function (source,players)
   s.call(skynet.getenv("node"),sceneNode[skynet.getenv("node")][1].srv,"enterScene",players)
end

s.resp.freeScene = function(source,node,id)
   sceneNode[node][id].status  = STATUS.WAIT
   skynet.error("free scene success")
end

s.init = function()
   skynet.error("launch scene mgr----------")
end

s.start(...)

local skynet = require "skynet"
local skynetManager = require "skynet.manager"
local serviceConfig = require "serviceConfig"
local cluster = require "skynet.cluster"

skynet.start(function ()
      -- 初始化

      local currNode = skynet.getenv("node")
      local nodecfg=serviceConfig[currNode]

      local nodemgr = skynet.newservice("nodemgr","nodemgr",0)
      skynet.name("nodemgr",nodemgr)

      cluster.reload(serviceConfig.cluster)
      cluster.open(currNode)

      for index, value in ipairs(serviceConfig[currNode].gateway) do
         local service = skynet.newservice("gateway","gateway",index)
         skynet.name("gateway"..index,service)
      end

      for index, value in ipairs(serviceConfig[currNode].login) do
         local service = skynet.newservice("login","login",index)
         skynet.name("login"..index,service)
      end

      local agentNode = serviceConfig.agentmgr.node
      if currNode == agentNode then
         local service = skynet.newservice("agentmgr","agentmgr",0)
         skynet.name("agentmgr",service)
      else
         local proxy = cluster.proxy(agentNode,"agentmgr")
         skynet.name("agentmgr",proxy)
      end

      local sceneMgrNode = serviceConfig.scenemgr.node

      if currNode == sceneMgrNode then
         local service = skynet.newservice("scenemgr","scenemgr",0)
         skynet.name("scenemgr",service)
      else
         local proxy = cluster.proxy(sceneMgrNode,"scenemgr")
         skynet.name("scenemgr",proxy)
      end

      --skynet.call("scenemgr","lua","createScene")

      if currNode == "node2" then
         skynet.error("requre create scene")
         --cluster.call(serviceConfig.scenemgr.node,"scenemgr","createScene")
         skynet.call("scenemgr","lua","createScene")
      end

      -- for _, sceneId in pairs(serviceConfig.scene[currNode]) do
      --    local srv = skynet.newservice("scene","scene",sceneId)
      --    skynet.name("scene"..sceneId,srv)
      -- end

      local db = skynet.newservice("mysql","db",0)
      skynetManager.name("db",db)
      skynet.error("start successed")

      skynet.exit()
end)

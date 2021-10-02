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

      -- skynet.error("[start main]")
      -- skynet.newservice("gateway","gateway",1)
      -- local login1 = skynet.newservice("login","login1",2)
      -- local login2 = skynet.newservice("login","login2",3)
      -- local db = skynet.newservice("mysql","db",4)
      -- skynetManager.name("login1",login1)
      -- skynetManager.name("login2",login2)
      -- skynetManager.name("db",db)

      --print(skynet.call("db","lua","login",1,1))
      --skynet.call("db","lua","regist","2694273649@qq.com","杨启玢","123456")
      -- 退出自身
      skynet.exit()
end)

local skynet = require "skynet"

skynet.start(function ()
      -- 初始化
      skynet.error("[start main]")
      -- 退出自身
      skynet.exit()
end)

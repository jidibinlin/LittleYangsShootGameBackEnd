local skynet = require "skynet"
local s = require "service"

s.resp.newservice = function (source,name,...)
   skynet.error("init a new agent")
   local srv = skynet.newservice(name,...)
   return srv
end

s.start(...)

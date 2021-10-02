local skynet = require "skynet"
local s = require "service"

s.client = {}
s.resp.client = function (source,fd,cmd,msg)
   skynet.error("login client ",cmd)
   if s.client[cmd] then
      local ret_msg = s.client[cmd](fd,msg,source)
      skynet.send(source,"lua","send_by_fd",ret_msg)
   else
      skynet.error("s.resp.client fail",cmd)
   end
end

local send_login_res = function (fd,msg)
   skynet.call("gate","lua","send_by_fd",fd,msg)
end

s.client.login = function (fd,msg,source)
   --skynet.error("login recv: "..msg.cmd.." "..msg.playerid.." "..msg.password)
   --return {cmd="Login",stat=-1,"测试"}
   local gate = source
   local node = skynet.getenv("node")
   local send = nil

   if not skynet.send("db","lua","login",msg.playerid,msg.playername,msg.password) then
      send = {cmd="login",stat=2,reason="密码错误或未注册"}
      return send
   end

   --skynet.error("login db pass")

   local isok,agent = skynet.call("agentmgr","lua","reqlogin",msg.playerid,node,gate)

   if not isok then
      send = {cmd = "login",stat=2,reason="请求agentmgr失败"}
      return send
   end
   --回应gate
   local isok = skynet.call(gate,"lua","sure_agent",fd,msg.playerid,agent)
   if not isok then
      send = {cmd="login",stat=2,reason="gate注册失败"}
      return send
   end
   skynet.error("login succ"..msg.playerid)
   send = {cmd="login",stat=1,reason="登录成功"}
   skynet.fork(send_login_res,fd,msg)
   return send
end

s.start(...)

local skynet = require "skynet"
local s = require "service"

s.client = {}
s.resp.client = function (source,fd,cmd,msg)
   skynet.error("login client dispatch ",cmd," login-",6)
   if s.client[cmd] then
      local ret_msg = s.client[cmd](fd,msg,source)
      skynet.send(source,"lua","send_by_fd",fd,ret_msg)
   else
      skynet.error("s.resp.client fail",cmd)
   end
end

s.client.login = function (fd,msg,source)
   skynet.error("login called "..msg.cmd.." "..msg.playerid.." "..msg.password.." login-",16)
   --return {cmd="Login",stat=-1,"测试"}
   local gate = source
   local node = skynet.getenv("node")

   local isok = skynet.call("db","lua","login",msg.playerid,msg.password)

   if not isok  then
      skynet.error(msg.playerid.."登录失败 密码错误或未注册")
      return {id=2, cmd="loginResp",stat=2,reason="密码错误或未注册"}
   end

   --skynet.error("login db pass")

   local isok,agent = skynet.call("agentmgr","lua","reqlogin",msg.playerid,node,gate)

   if not isok then
      skynet.error(msg.playerid.."登录失败,请求agentmgr失败")
      return {id=2,cmd = "loginResp",stat=2,reason="请求agentmgr失败"}
   end
   --回应gate
   local isok = skynet.call(gate,"lua","sure_agent",fd,msg.playerid,agent)
   if not isok then
      skynet.error(msg.playerid.."登录失败，gate注册失败")
      return {id=2,cmd="loginResp",stat=2,reason="gate注册失败"}
   end
   skynet.error("login succ"..msg.playerid)
   return {id=2,cmd="loginResp",stat=1,reason="登录成功"}
end

s.start(...)

local skynet = require "skynet"
local cluster = require "skynet.cluster"

local M={
   name = "",
   id=0,
   -- customize exit init and resp func
   exit = nil,
   init = nil,
   resp = {},
}

function traceback(error)
   skynet.error(tostring(error))
   skynet.error(debug.traceback())
end

local dispatch = function (session,address,cmd,...)
   --skynet.error("received call",address,cmd)
   local fun = M.resp[cmd]
   if not fun then
      skynet.error(fun..":"..cmd.." isNULL")
      skynet.ret()
      return
   end
   local ret = table.pack(xpcall(fun,traceback,address,...))
   local isok = ret[1]
   if not isok then
      skynet.ret()
      return
   end
   skynet.retpack(table.unpack(ret,2))
end

function init()
   skynet.error("init is called")
   skynet.dispatch("lua",dispatch)
   if M.init then
      M.init()
   end
end

function M.call(node,srv,...)
   skynet.error("lualib service call called")
   local currNode = skynet.getenv("node")
   if node == currNode then
      skynet.error("lualib service call called 47")
      return skynet.call(srv,"lua",...)
   else
      return cluster.call(node,srv,...)
   end
end

function M.send(node,srv,...)
   skynet.error("lualib service send called")
   local currNode = skynet.getenv("node")
   if node == currNode then
      return skynet.send(srv,"lua",...)
   else
      return cluster.send(node,srv,...)
   end
end

function M.tablePrint(msg)
   for key, value in pairs(msg) do
      if type(value) == "table" then
         print(key,M.tablePrint(value))
         --tablePrint(value)
      else
         print(key,value)
      end
   end
end

function M.start(name,id,...)
   M.name = name
   if name~="agent" then
      M.id = tonumber(id)
   else
      M.id = tostring(id)
   end
   --M.id = id
   skynet.start(init)
end

return M;

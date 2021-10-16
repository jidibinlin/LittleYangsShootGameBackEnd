local skynet = require "skynet"
local s= require "service"
local serviceConfig = require "serviceConfig"

STATUS = {
   LOGIN = 1,
   GAME = 2,
   WAIT = 3,
   LOGOUT = 4,
   PVP = 5,

}

local players = {}
local pvp = {}

function mgrplayer()
   local m = {
      playerid = nil,
      node = nil,
      agent = nil,
      status = nil,
      gate = nil,
   }
   return m
end

s.resp.reqlogin = function(source,playerid,node,gate)
   print("agent mgr reqlogin playerid",playerid)
   local mplayer = players[playerid]

   if mplayer and mplayer.status == STATUS.LOGOUT then
      skynet.error("reqlogin fail, player are logouting"..playerid)
      return false
   end

   if mplayer and mplayer.status == STATUS.LOGIN then
      skynet.error("reqlogin fail,player are logining"..playerid)
      return false
   end
   if mplayer and mplayer.status == STATUS.PVP then
      skynet.error("reqlogin fail,player are pvp"..playerid)
      return false
   end
   if mplayer and mplayer.status == STATUS.GAME then
      skynet.error("reqlogin fail, player are gaming"..playerid)
      return false
   end

   print("mplayer:",mplayer)
   if mplayer then
      local pNode = mplayer.node
      local pAgent = mplayer.agent
      local pGate = mplayer.gate
      mplayer.status = STATUS.LOGOUT
      s.call(node,pAgent,"kick")
      s.send(node,pAgent,"exit")
      s.send(node,pGate,"send",playerid,{"kick","顶替下线"})
      s.call(node,pGate,"kick",playerid)
   end

   local player = mgrplayer()
   player.playerid = playerid
   player.node = node
   player.gate = gate
   player.agent= nil
   player.status = STATUS.LOGIN
   players[playerid] = player
   local agent = s.call(node,"nodemgr","newservice","agent","agent",playerid)
   player.agent = agent
   player.status = STATUS.WAIT
   skynet.error("init agent success")
   return true,agent
end

s.resp.pvp = function(source,playerid)
   local player = players[playerid]
   if player.status == STATUS.WAIT then
      player.status = STATUS.PVP
      table.insert(pvp,player)
   end
end

s.resp.reqkick = function (source,playerid,reason)
   local mplayer = players[playerid]
   if not mplayer then
      return false
   end
   if mplayer.status ~= STATUS.GAME then
      return false
   end

   s.call(mplayer.node,mplayer.agent,"kick")
   s.send(mplayer.node,mplayer.agent,"exit")
   s.send(mplayer.node,mplayer.gate,"kick",playerid)
   players[playerid]=nil
   return true
end

-- s.resp = function(source,players)

-- end
s.resp.leave_scene = function (source,playerid)
   players[playerid].status = STATUS.WAIT
   return true
end

s.init = function()
   skynet.fork(function()
         while true do
            if #pvp >= 2 then
               --TODO: start the game through scenemanager
               local foo = {}
               for i = 1, 2 do
                  local p = table.remove(pvp,1)
                  table.insert(foo,p)
                  p.status = STATUS.GAME
               end
               skynet.error("here is running",#foo)
               s.call(serviceConfig.scenemgr.node,"scenemgr","enterScene",foo)
            end
            skynet.sleep(1000)
         end
   end
   )
end

s.start(...)

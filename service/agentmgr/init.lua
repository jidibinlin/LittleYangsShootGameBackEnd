local skynet = require "skynet"
local s= require "service"

STATUS = {
   LOGIN = 1,
   GAME = 2,
   LOGOUT = 4,
}

local players = {}

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
   player.status = STATUS.GAME
   skynet.error("init agent success")
   return true,agent
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

s.start(...)

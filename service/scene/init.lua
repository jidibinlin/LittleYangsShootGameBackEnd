local skynet = require "skynet"
local serviceConfig = require "serviceConfig"
local idToName = require "protoConfig"
local s = require "service"

players={}
local playerNum=0


local function player()
   local m = {
      playerid = nil,
      node = nil,
      agent = nil,
      queeKey = true,
      msgquee={},
   }
   return m
end

local function broadcast(frame)
   for _, player in pairs(players) do
      local count =  #player.msgquee
      if count>0 then
         local msg = table.remove(player.msgquee,1)
         for _, broadPlayer in pairs(players) do
            if broadPlayer.playerid == player.playerid then
               goto continue
            end
            s.send(broadPlayer.node,broadPlayer.agent,"send",msg)
            ::continue::
         end
      end
      --player.posi = count
   end
end

local function update(frame)
   -- TODO update fight info
   broadcast(frame)
end
local function kick(playerid)
   local player = players[playerid]
   s.call(player.node,player.agent,"client","leaveScene",{reason="you are kicked"})
end

local startGame = function ()
   --TODO: send startGame proto
   skynet.error("startGame require client create player")
   local playerIds = {}

   for _, player in pairs(players) do
      print("insert player id ",player.playerid)
      table.insert(playerIds,player.playerid)
   end

   for _, player in pairs(players) do
      s.send(player.node,player.agent,"send",{id=5,cmd="startGame",players=playerIds})
   end
   skynet.fork(function()
         local stime = skynet.now()
         local frame = 0

         while true do
            if playerNum <=1 then
               for playerid, _ in pairs(players) do
                  kick(playerid)
               end
               s.call(serviceConfig.scenemgr.node,"scenemgr","freeScene",skynet.getenv("node"),s.id)
               return
            end

            frame = frame+1
            --local beforeBroad = skynet.now()
            local isok,err = pcall(update,frame)
            --skynet.error("broad consume",beforeBroad,(skynet.now()))
            if not isok then
               skynet.error(err)
            end
            skynet.error("current frame",frame)
            local etime = skynet.now()
            local waittime = frame*2-(etime-stime)
            if waittime <=0 then
               waittime = 1
            end
            skynet.sleep(waittime)
         end
   end)
end

s.resp.enterScene = function(source,p)
   skynet.error("scene enter scene",p)

   for _, enPlayer in pairs(p)do
      local foo = player()
      foo.playerid = enPlayer.playerid
      foo.node = enPlayer.node
      foo.agent = enPlayer.agent
      s.call(foo.node,foo.agent,"enterScene",foo.node,skynet.self())
      print(enPlayer.playerid.."enter scene")
      --table.insert(players,foo)
      players[foo.playerid] = foo
      playerNum = playerNum+1
   end

   startGame()

end

s.resp.broadcastCtoS = function(source,playerid,msg)

   if playerNum <=1 then
      return
   end

   table.insert(players[playerid].msgquee,(msg))
   --player.queeKey = true
end

s.resp.requickshot = function (source,playerid,node,agent,quickshot)
   local msgquee = players[playerid].msgquee
   table.insert(msgquee,quickshot)
end


s.resp.leave = function (source,playerid)
   if not players[playerid] then
      return false
   end
   --local player = players[playerid]
   players[playerid]=nil
   playerNum = playerNum-1
   skynet.error(playerid,"leave scene")
   return s.call(serviceConfig.scenemgr.node,"agentmgr","leaveScene",playerid)
end

s.init = function ()

end

s.start(...)

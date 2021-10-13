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
         local msg = table.remove(player.msgquee)
         for _, broadPlayer in pairs(players) do
            if broadPlayer.playerid == player.playerid then
               goto continue
            end
            --for i = (player.posi), count do
            --skynet.error("send broadcastCtoS to",broadPlayer.playerid,"count",count,"posi",player.posi)
            s.send(broadPlayer.node,broadPlayer.agent,"send",msg)
            --end
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

local startGame = function ()
   --TODO: send startGame proto
   skynet.error("startGame require client create player")
   local playerIds = {}

   for _, player in pairs(players) do
      print("insert player id ",player.playerid)
      table.insert(playerIds,player.playerid)
   end
   -- for key, value in pairs(playerIds) do
   --    print(value)
   -- end

   for _, player in pairs(players) do
      s.send(player.node,player.agent,"send",{id=5,cmd="startGame",players=playerIds})
   end
   skynet.fork(function()
         local stime = skynet.now()
         local frame = 0

         while true do
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
   end
   )
end

s.resp.enterScene = function (source,playerid,node,agent)
   skynet.error(playerid.."进入场景中")
   if players[playerid] then
      return false
   end
   local player = player()
   player.playerid = playerid
   player.node = node
   player.agent = agent
   playerNum = playerNum+1;
   players[player.playerid]=player

   if playerNum == 2 then
      startGame()
   end
end

s.resp.broadcastCtoS = function(source,playerid,msg)
   --skynet.error("broadcastCtoS")
   -- local player = player[playerid]

   -- while  player.queeKey == false do
   -- end

   --player.queeKey = false
   table.insert(players[playerid].msgquee,(msg))
   --player.queeKey = true
end

-- TODO sync time with players


s.resp.requickshot = function (source,playerid,node,agent,quickshot)
   local msgquee = players[playerid].msgquee
   table.insert(msgquee,quickshot)
end

s.resp.leave = function (source,playerid)
   if not players[playerid] then
      return false
   end
   players[playerid]=nil
   -- TODO return leave msg
end


s.init = function ()
end

s.start(...)

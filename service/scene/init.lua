local skynet = require "skynet"
local serviceConfig = require "serviceConfig"
local s = require "service"

players={}
local playerNum=0

local function player()
   local m = {
      playerid = nil,
      node = nil,
      agent = nil,
      msgquee={},
   }
   return m
end

local function broadcast(frame)
   --skynet.error("广播")
   for index, player in ipairs(players) do
      local msg = table.remove(player.msgquee,1)
      local frameMsg = {cmd="frame",frame=frame}
      s.send(player.node,player.agent,"send",frameMsg)
      s.send(player.node,player.agent,"send",msg)
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
      print("insert player id ",player.id)
      table.insert(playerIds,player.playerid)
   end

   for _, player in pairs(players) do
      s.send(player.node,player.agent,"send",{id=5,cmd="startGame",players=playerIds})
   end
   skynet.fork(function()
         local stime = skynet.now()
         local frame = 0

         while true do
            frame = frame+1
            local isok,err = pcall(update,frame)

            if not isok then
               skynet.error(err)
            end
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
   player.id = playerid
   player.node = node
   player.agent = agent
   playerNum = playerNum+1;
   players[player.id]=player

   if playerNum == 2 then
      startGame()
   end
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

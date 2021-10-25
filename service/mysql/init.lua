local skynet = require "skynet"
local mysql = require "skynet.db.mysql"
local s = require "service"

local idle = {}
local walk={}


local function getConn ()
   for key, conn in pairs(idle) do
      idle[conn]=nil
      walk[conn]=conn
      return conn
   end
   return getConn();
end

local backConn = function (conn)
   idle[conn]=conn
   walk[conn]=nil
end


s.resp.login = function(source,playerid,password)
   print("playerid",playerid,"password",password)
   local sql = "select password from player where playerid =".."\'"..playerid.."\'"

   local db = nil
   db = getConn()

   local res = db:query(sql)

   for key, value in pairs(res) do
      print(key,value)
   end

   if tostring(res[1].password) == tostring(password) then
      return true
   else
      return false
   end

   backConn(db)
end

s.resp.regist = function (source,playerid,playername,password)
   print(playerid,playername,password)
   local db = getConn()
   local sql = "insert into player(playerid,playername,password) values (\'" ..playerid.. "\',\'".. playername.."\',"..
      "\'"..password.."\'"..")"
   print(sql)

   local res =  db:query(sql)

   if not res.err then
      backConn(db)
      return false
   end

   backConn(db)
   return true

   -- for key, value in pairs(res) do
   --       print(key,value)
   -- end

   -- print(table.concat(res,","))
end

s.init=function ()
   for i = 1, 8 do
      local db = mysql.connect({
            host="119.29.148.225",
            port=3306,
            database="littlegame",
            user="root",
            password="Bin269427...",
            max_package_size=1024*1024,
            on_connect=nil
      })
      idle[db]=db
   end
end

s.start(...)

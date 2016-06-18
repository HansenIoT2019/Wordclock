--TODO:

configFile="config.lua"


function sendWebPage(conn,answertype)
  if (ssid == nil) then
    ssid="Not set"
  end
  if (sntpserverhostname == nil) then
    sntpserverhostname="ptbtime1.ptb.de"
  end
  if (timezoneoffset == nil) then
    timezoneoffset=1
  end
  buf="HTTP/1.1 200 OK\nServer: NodeMCU\nContent-Type: text/html\n\n"
  buf = buf .. "<html><body>\n"
  buf = buf .. "<h1>Welcome to the WordClock</h1>"
  buf = buf.. "<h2>Configuration</h2><form action=\"\" method=\"POST\">"
  buf = buf.. "<label for=\"ssid\">WIFI-SSID: <input id=\"ssid\" name=\"ssid\" value=\"" .. ssid .. "\"></label><br/>"
  buf = buf.. "<label for=\"password\">Password: <input id=\"password\" name=\"password\"></label><br/>"
  buf = buf.. "<label for=\"sntpserver\">SNTP Server: <input id=\"sntpserver\" name=\"sntpserver\" value=\"" .. sntpserverhostname .. "\"></label><br/>"
  buf = buf.. "<label for=\"timezoneoffset\">Offset from UTC: <input id=\"timezoneoffset\" name=\"timezoneoffset\" value=\"" .. timezoneoffset .. "\"></label><br/>"
  buf = buf.. "<input type=\"submit\" value=\"Configure Clock\"></form>"
  if answertype>1 then
   buf = buf .. "<h2>New configuration saved</h2\n>"
  end 
  buf = buf .. "\n</body></html>"
  conn:send(buf)
  buf=nil
end

function startWebServer()
 srv=net.createServer(net.TCP)
 srv:listen(80,function(conn)
  conn:on("receive", function(conn,payload)
   if (payload:find("GET /") ~= nil) then
   --here is code for handling http request from a web-browser
    ssid, password, bssid_set, bssid = wifi.sta.getconfig()
    sendWebPage(conn,1)
    conn:on("sent", function(conn) conn:close() end)
   else if (payload:find("POST /") ~=nil) then
     --code for handling the POST-request (updating settings)
     _, postdatastart = payload:find("\r\n\r\n")
     --Next lines catches POST-requests without POST-data....
     if postdatastart==nil then postdatastart = 1 end
     postRequestData=string.sub(payload,postdatastart+1)
     local _POST = {}
     for i, j in string.gmatch(postRequestData, "(%w+)=([^&]+)&*") do
       _POST[i] = j
     end
     postRequestData=nil
     if ((_POST.ssid~=nil) and (_POST.password~=nil) and (_POST.sntpserver~=nil) and (_POST.timezoneoffset~=nil)) then
      -- Safe configuration:
      file.remove(configFile)
      file.open(configFile, "w+")
      w = file.writeline
      w("-- Config")
      w("wifi.sta.config(\"" .. _POST.ssid .. "\",\"" .. _POST.password .. "\")")
      w("sntpserverhostname=\"" .. _POST.sntpserver .. "\"")
      w("timezoneoffset=\"" .. _POST.timezoneoffset .. "\"")
      file.close()
      sendWebPage(conn,2)
     else
      ssid, password, bssid_set, bssid = wifi.sta.getconfig()
      sendWebPage(conn,1)
      conn:on("sent", function(conn) conn:close() end)
     end
    else
     --here is code, if the connection is not from a webbrowser, i.e. telnet or nc
     global_c=conn
     function s_output(str)
      if(global_c~=nil)
        then global_c:send(str)
      end
     end
     node.output(s_output, 0)
     global_c:on("receive",function(c,l)
       node.input(l)
     end)
     global_c:on("disconnection",function(c)
       node.output(nil)
       global_c=nil
     end)
     print("Welcome to WS2812Clock")
     
    end
   end
   end)
    
  conn:on("disconnection", function(c)
          node.output(nil)        -- un-register the redirect output function, output goes to serial
       end)
 end)

end

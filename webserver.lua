--TODO:

configFile="config.lua"

sentBytes=0
function sendPage(conn, nameOfFile, replaceMap)
  
  conn:on("sent", function(conn) 
    if (sentBytes == 0) then
        conn:close() 
        print("Page sent")
    else 
        sendPage(conn, nameOfFile, replaceMap)
    end
  end)

  if file.open(nameOfFile, "r") then
    local buf=""
    if (sentBytes <= 0) then
        buf=buf .. "HTTP/1.1 200 OK\r\n"
        buf=buf .. "Content-Type: text/html\r\n"
        buf=buf .. "Connection: close\r\n"
        buf=buf .. "Date: Thu, 29 Dec 2016 20:18:20 GMT\r\n"
        buf=buf .. "\r\n\r\n"
    end
    -- amount of sent bytes is always zero at the beginning (so no problem)
    file.seek("set", sentBytes)
    
    local line = file.readline()
    
    while (line ~= nil) do
        -- increase the amount of sent bytes
        sentBytes=sentBytes+string.len(line)
        
        -- all placeholder begin with a $, so search for it in the current line
        if (line:find("$") ~= nil) then
            -- Replace the placeholder with the dynamic content
            if (replaceMap ~= nil) then
                for key,value in pairs(replaceMap) 
                do 
                    line = string.gsub(line, key, value)
                end
            end
        end
        buf = buf .. line
        
        -- Sent after 1k data
        if (string.len(buf) >= 700) then
            line=nil
            conn:send(buf)
            -- end the function, this part is sent
            return 
        else
            -- fetch the next line
            line = file.readline()
        end
    end
    --reset amount of sent bytes, as we reached the end
    sentBytes=0
    -- send the rest
    conn:send(buf)
  end
  
end

function fillDynamicMap()
    replaceMap = {}
    ssid, _ = wifi.sta.getconfig()

    if (ssid == nil) then
        ssid="Not set"
    end
    if (sntpserverhostname == nil) then
        sntpserverhostname="ptbtime1.ptb.de"
    end
    if (timezoneoffset == nil) then
        timezoneoffset=1
    end
    -- Set the default color, if nothing is set
    if (color == nil) then
        color=string.char(0,0,250)
    end
    if (color1 == nil) then
        color1=color
    end
    if (color2 == nil) then
        color2=color
    end
    if (color3 == nil) then
        color3=color
    end
    if (color4 == nil) then
        color4=color
    end
    local hexColor = "#" .. string.format("%02x",string.byte(color,1)) .. string.format("%02x",string.byte(color,2)) .. string.format("%02x",string.byte(color,3))
    local hexColor1 = "#" .. string.format("%02x",string.byte(color1,1)) .. string.format("%02x",string.byte(color1,2)) .. string.format("%02x",string.byte(color1,3))
    local hexColor2 = "#" .. string.format("%02x",string.byte(color2,1)) .. string.format("%02x",string.byte(color2,2)) .. string.format("%02x",string.byte(color2,3))
    local hexColor3 = "#" .. string.format("%02x",string.byte(color3,1)) .. string.format("%02x",string.byte(color3,2)) .. string.format("%02x",string.byte(color3,3))
    local hexColor4 = "#" .. string.format("%02x",string.byte(color4,1)) .. string.format("%02x",string.byte(color4,2)) .. string.format("%02x",string.byte(color4,3))
    

    
    replaceMap["$SSID"]=ssid
    replaceMap["$SNTPSERVER"]=sntpserverhostname
    replaceMap["$TIMEOFFSET"]=timezoneoffset
    replaceMap["$THREEQUATER"]=(threequater and "checked" or "")
    replaceMap["$ADDITIONAL_LINE"]=""
    replaceMap["$HEXCOLOR"]=hexColor
    replaceMap["$HEXCOLOR1"]=hexColor1
    replaceMap["$HEXCOLOR2"]=hexColor2
    replaceMap["$HEXCOLOR3"]=hexColor3
    replaceMap["$HEXCOLOR4"]=hexColor4
    return replaceMap   
end

function startWebServer()
 srv=net.createServer(net.TCP)
 srv:listen(80,function(conn)
  conn:on("receive", function(conn,payload)
   
   if (payload:find("GET /") ~= nil) then
   --here is code for handling http request from a web-browser

    if (sendPage ~= nil) then
       print("Sending webpage.html ...")
       -- Load the sendPagewebcontent
       replaceMap=fillDynamicMap()
       sendPage(conn, "webpage.html", replaceMap)
    end
    
   else if (payload:find("POST /") ~=nil) then
    --code for handling the POST-request (updating settings)
     _, postdatastart = payload:find("\r\n\r\n")
     --Next lines catches POST-requests without POST-data....
     if postdatastart==nil then postdatastart = 1 end
     local postRequestData=string.sub(payload,postdatastart+1)
     local _POST = {}
     for i, j in string.gmatch(postRequestData, "(%w+)=([^&]+)&*") do
       _POST[i] = j
     end

     --- Do the magic!
     if (_POST.action ~= nil and _POST.action == "Reboot") then
        node.restart()
     end

    if ((_POST.ssid~=nil) and (_POST.sntpserver~=nil) and (_POST.timezoneoffset~=nil)) then
        print("New config!")
        if (_POST.password==nil) then
            _, password, _, _ = wifi.sta.getconfig()
            print("Restoring password : " .. password)
            _POST.password = password
            password = nil
        end
        -- Safe configuration:
        file.remove(configFile .. ".new")
        sec, _ = rtctime.get()
        file.open(configFile.. ".new", "w+")
        file.write("-- Config\n" .. "wifi.sta.config(\"" .. _POST.ssid .. "\",\"" .. _POST.password .. "\")\n" .. "sntpserverhostname=\"" .. _POST.sntpserver .. "\"\n" .. "timezoneoffset=\"" .. _POST.timezoneoffset .. "\"\n")
        if ( _POST.fcolor ~= nil) then
            -- color=string.char(_POST.green, _POST.red, _POST.blue)  
            print ("Got fcolor: " .. _POST.fcolor)
            local hexColor=string.sub(_POST.fcolor, 4)
            local red = tonumber(string.sub(hexColor, 1, 2), 16)
            local green = tonumber(string.sub(hexColor, 3, 4), 16)
            local blue = tonumber(string.sub(hexColor, 5, 6), 16)
            color=string.char(green, red, blue)
        end
        if ( _POST.colorMin1  ~= nil) then
            local hexColor=string.sub(_POST.colorMin1, 4)
            local red = tonumber(string.sub(hexColor, 1, 2), 16)
            local green = tonumber(string.sub(hexColor, 3, 4), 16)
            local blue = tonumber(string.sub(hexColor, 5, 6), 16)
            file.write("color1=string.char(" .. green .. "," .. red .. "," .. blue .. ")\n")
        end
        if ( _POST.colorMin2  ~= nil) then
            local hexColor=string.sub(_POST.colorMin2, 4)
            local red = tonumber(string.sub(hexColor, 1, 2), 16)
            local green = tonumber(string.sub(hexColor, 3, 4), 16)
            local blue = tonumber(string.sub(hexColor, 5, 6), 16)
            file.write("color2=string.char(" .. green .. "," .. red .. "," .. blue .. ")\n")
        end
        if ( _POST.colorMin3  ~= nil) then
            local hexColor=string.sub(_POST.colorMin3, 4)
            local red = tonumber(string.sub(hexColor, 1, 2), 16)
            local green = tonumber(string.sub(hexColor, 3, 4), 16)
            local blue = tonumber(string.sub(hexColor, 5, 6), 16)
            file.write("color3=string.char(" .. green .. "," .. red .. "," .. blue .. ")\n")
        end
        if ( _POST.colorMin4  ~= nil) then
            local hexColor=string.sub(_POST.colorMin4, 4)
            local red = tonumber(string.sub(hexColor, 1, 2), 16)
            local green = tonumber(string.sub(hexColor, 3, 4), 16)
            local blue = tonumber(string.sub(hexColor, 5, 6), 16)
            file.write("color4=string.char(" .. green .. "," .. red .. "," .. blue .. ")\n")
        end
        time = getTime(sec, timezoneoffset)
        file.write("color=string.char(" .. string.byte(color,1) .. "," .. string.byte(color, 2) .. "," .. string.byte(color, 3) .. ")\n")
        file.write("print(\"Config from " .. time.year .. "-" .. time.month .. "-" .. time.day .. " " .. time.hour .. ":" .. time.minute .. ":" .. time.second .. "\")\n")
        if (_POST.threequater ~= nil) then
            file.write("threequater=true\n")
        else
            file.write("threequater=nil\n") -- unset threequater
        end
        file.close()
        collectgarbage()
        sec=nil
        file.remove(configFile)
        print("Rename config")
        if (file.rename(configFile .. ".new", configFile)) then
            print("Successfully")
            dofile(configFile) -- load the new values
            replaceMap=fillDynamicMap()
            replaceMap["$ADDITIONAL_LINE"]="<h2><font color=\"green\">New configuration saved</font></h2>"
            sendPage(conn, "webpage.html", replaceMap)
        else
            replaceMap=fillDynamicMap()
            replaceMap["$ADDITIONAL_LINE"]="<h2><font color=\"red\">ERROR</font></h2>"
            sendPage(conn, "webpage.html", replaceMap)
        end
  else
      replaceMap=fillDynamicMap()
      replaceMap["$ADDITIONAL_LINE"]="<h2><font color=\"orange\">Not all parameters set</font></h2>"
      sendPage(conn, "webpage.html", replaceMap)
  end
    else
     print("Hello via telnet")
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
     print("Welcome to Word Clock")
     
    end
   end
   end)
    
  conn:on("disconnection", function(c)
          node.output(nil)        -- un-register the redirect output function, output goes to serial
          
          --reset amount of sent bytes, as we reached the end
          sentBytes=0
       end)
 end)

end

dofile("wlancfg.lua")
dofile("timecore.lua")
dofile("wordclock.lua")
dofile("displayword.lua")

timezoneoffset=1
ledPin=4
color=string.char(0,0,250)

connect_counter=0
-- Wait to be connect to the WiFi access point. 
tmr.alarm(0, 500, 1, function()
  connect_counter=connect_counter+1
  if wifi.sta.status() ~= 5 then
     print("Connecting to AP...")
     if (connect_counter % 2 == 0) then
        ws2812.write(ledPin, string.char(255,0,0):rep(114))
     else
       ws2812.write(ledPin, string.char(0,0,0):rep(114))
     end
  else
     tmr.stop(0)
     print('IP: ',wifi.sta.getip())

    --ptbtime1.ptb.de
    sntp.sync('ptbtime1.ptb.de',
     function(sec,usec,server)
      print('sync', sec, usec, server)
     end,
     function()
       print('failed!')
     end
   )
  end
  -- when no wifi available, open an accesspoint and ask the user
  if (connect_counter == 300) then -- 300 is 30 sec in 100ms cycle
    tmr.stop(0)
    wifi.setmode(wifi.SOFTAP)
    wifi.ap.config({ssid='clock',pwd='clock'})
    print("Waiting in access point >clock< for Clients")
    print("Please visit 192.168.4.1")
    
    dofile("webserver.lua")
  end
end)

tmr.alarm(1, 5000, 1 ,function()
 sec, usec = rtctime.get()
 time = getTime(sec, timezoneoffset)
 print("Time : " , sec)
 print("Local time : " .. time.year .. "-" .. time.month .. "-" .. time.day .. " " .. time.hour .. ":" .. time.minute .. ":" .. time.second)

 words = display_timestat(time.hour, time.minute)
 ledBuf = generateLEDs(words, color)
 -- Write the buffer to the LEDs
 ws2812.write(ledPin, ledBuf)
 
 for key,value in pairs(words) do 
    if (value > 0) then
      print(key,value) 
    end
 end
end)
